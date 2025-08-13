import ExcelJS from 'exceljs';
import pool from '../db.js';
import { z } from 'zod';

const zCustomer = z.object({
  customer_name: z.string().min(1),
  country_iso2: z.string().length(2).optional().nullable(),
  type: z.string().optional().nullable(),
  commercial_registration: z.string().optional().nullable(),
  vat_number: z.string().optional().nullable(),
  is_active: z.coerce.number().optional().default(1),
});

const zContact = z.object({
  customer_name: z.string().min(1),
  role: z.string().optional().nullable(),
  contact_name: z.string().min(1),
  email: z.string().email().optional().nullable(),
  phone: z.string().optional().nullable(),
  is_primary: z.coerce.number().optional().default(0),
});

const zProject = z.object({
  project_name: z.string().min(1),
  customer_name: z.string().min(1),
  segment: z.string().optional().nullable(),
  service_line: z.string().optional().nullable(),
  partner: z.string().optional().nullable(),
  status: z.string().optional().nullable(),
  po_status: z.string().optional().nullable(),
  invoice_status: z.string().optional().nullable(),
  contract_value: z.coerce.number().optional().default(0),
  currency_iso3: z.string().length(3).optional().nullable(),
  start_date: z.string().optional().nullable(),
  end_date: z.string().optional().nullable(),
});

const zTerm = z.object({
  project_name: z.string().min(1),
  seq: z.coerce.number().int().min(1),
  percentage: z.coerce.number().min(0).max(100),
  description: z.string().min(1),
  due_date: z.string().optional().nullable(),
  status: z.string().optional().nullable(),
});

function wsToJson(sheet){
  const rows = [];
  const header = (sheet.getRow(1).values||[]).map(v=>String(v||'').trim().replace(/\*$/,'').toLowerCase());
  sheet.eachRow((row,idx)=>{
    if(idx===1) return;
    const obj = {};
    header.forEach((h,i)=>{ obj[h] = row.getCell(i+1).value==null ? null : String(row.getCell(i+1).value).trim(); });
    rows.push(obj);
  });
  return rows;
}

async function ensureStatus(conn, type, name){
  if(!name) return null;
  const [[row]] = await conn.query('SELECT id FROM statuses WHERE type=? AND name=?',[type,name]);
  if(row) return row.id;
  const [r] = await conn.query('INSERT INTO statuses(type,name,is_active) VALUES (?,?,1)',[type,name]);
  return r.insertId;
}

export async function template(req,res){
  // Serve the template you generated earlier (adjust if you moved it)
  res.download('/mnt/data/pm-bulk-template.xlsx','pm-bulk-template.xlsx');
}

export async function importExcel(req,res,next){
  try{
    if(!req.file) return res.status(400).json({error:'file is required'});
    const wb = new ExcelJS.Workbook();
    await wb.xlsx.load(req.file.buffer);

    const tabs = Object.fromEntries(
      wb.worksheets.map(ws => [ws.name, wsToJson(ws)])
    );

    const customers = (tabs['Customers']||[]).map(zCustomer.parse);
    const contacts  = (tabs['Contacts']||[]).map(zContact.parse);
    const projects  = (tabs['Projects']||[]).map(zProject.parse);
    const terms     = (tabs['PaymentTerms']||[]).map(zTerm.parse);

    // Validate term totals per project (must be 100%)
    const sumByProject = {};
    for(const t of terms){
      sumByProject[t.project_name] = (sumByProject[t.project_name]||0)+Number(t.percentage||0);
    }
    const bad = Object.entries(sumByProject).filter(([_,sum])=> Math.round(sum) !== 100);
    if(bad.length) return res.status(400).json({error:'Percentages must total 100% per project', details:bad});

    const conn = await pool.getConnection();
    try{
      await conn.beginTransaction();

      // Upsert customers
      for(const c of customers){
        const [[row]] = await conn.query('SELECT id FROM customers WHERE name=?', [c.customer_name]);
        if(row){
          await conn.query(
            'UPDATE customers SET country_iso2=?, name=?, is_active=?, commercial_registration=?, vat_number=? WHERE id=?',
            [c.country_iso2||null, c.customer_name, c.is_active||1, c.commercial_registration||null, c.vat_number||null, row.id]
          );
        }else{
          await conn.query(
            'INSERT INTO customers(name,country_iso2,is_active,commercial_registration,vat_number) VALUES (?,?,?,?,?)',
            [c.customer_name, c.country_iso2||null, c.is_active||1, c.commercial_registration||null, c.vat_number||null]
          );
        }
      }

      // Contacts
      for(const ct of contacts){
        const [[cust]] = await conn.query('SELECT id FROM customers WHERE name=?',[ct.customer_name]);
        if(!cust) continue;
        await conn.query(
          'INSERT INTO customer_contacts(customer_id,role,name,email,phone,is_primary) VALUES (?,?,?,?,?,?)',
          [cust.id, ct.role||null, ct.contact_name, ct.email||null, ct.phone||null, ct.is_primary?1:0]
        );
      }

      // Projects
      for(const p of projects){
        const [[cust]] = await conn.query('SELECT id FROM customers WHERE name=?',[p.customer_name]);
        if(!cust) continue;
        const statusId       = p.status        ? await ensureStatus(conn,'project_status',p.status) : null;
        const poStatusId     = p.po_status     ? await ensureStatus(conn,'po_status',p.po_status)     : null;
        const invStatusId    = p.invoice_status? await ensureStatus(conn,'invoice_status',p.invoice_status): null;

        const [[row]] = await conn.query('SELECT id FROM projects WHERE name=?',[p.project_name]);
        if(row){
          await conn.query(`
            UPDATE projects
            SET customer_id=?, segment_id=NULL, service_line_id=NULL, partner_id=NULL,
                status_id=?, po_status_id=?, invoice_status_id=?,
                backlog_2025=backlog_2025,  -- untouched if present
                created_by=created_by
            WHERE id=?`,
            [cust.id, statusId, poStatusId, invStatusId, row.id]
          );
          await conn.query(`UPDATE projects SET contract_value=? WHERE id=?`, [p.contract_value||0, row.id]);
        }else{
          const [ins] = await conn.query(`
            INSERT INTO projects(name, customer_id, status_id, po_status_id, invoice_status_id, backlog_2025, created_by, segment_id, service_line_id, partner_id, payment_term_id, invoice_status_id)
            VALUES (?,?,?,?,?,0,NULL,NULL,NULL,NULL,NULL,?)`,
            [p.project_name, cust.id, statusId, poStatusId, invStatusId, invStatusId]
          );
          await conn.query(`UPDATE projects SET contract_value=? WHERE id=?`, [p.contract_value||0, ins.insertId]);
        }
      }

      // Terms
      for(const t of terms){
        const [[proj]] = await conn.query('SELECT id, contract_value FROM projects WHERE name=?',[t.project_name]);
        if(!proj) continue;
        const termStatusId = t.status ? await ensureStatus(conn,'term_status',t.status) : null;
        const [[exists]] = await conn.query('SELECT id FROM project_terms WHERE project_id=? AND seq=?',[proj.id, t.seq]);
        if(exists){
          await conn.query(
            'UPDATE project_terms SET percentage=?, description=?, due_date=?, term_status_id=? WHERE id=?',
            [t.percentage, t.description, t.due_date||null, termStatusId, exists.id]
          );
        }else{
          await conn.query(
            'INSERT INTO project_terms(project_id, seq, percentage, description, due_date, term_status_id) VALUES (?,?,?,?,?,?)',
            [proj.id, t.seq, t.percentage, t.description, t.due_date||null, termStatusId]
          );
        }
      }

      await conn.commit();
      conn.release();
      res.json({ok:true, inserted:true});
    }catch(e){
      try{ await pool.query('ROLLBACK'); }catch{}
      throw e;
    }
  }catch(err){ next(err); }
}
