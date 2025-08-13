set -euo pipefail

BACK=~/projects/backend
FRONT=~/projects/frontend

########################################
# Backend: routes + controllers
########################################

# deps
cd "$BACK"
npm i exceljs multer zod

# dashboard controller
mkdir -p src/controllers src/routes
cat > src/controllers/dashboardController.js <<'JS'
import pool from '../db.js';

function moneyExpr() {
  // contract_value * percentage/100, safe for NULLs
  return 'COALESCE(p.contract_value,0) * COALESCE(pt.percentage,0) / 100';
}

const NOT_PAID = `('Paid','Cancelled')`;

export async function summary(req,res,next){
  try{
    const conn = await pool.getConnection();

    const [[{total_projects}]] = await conn.query('SELECT COUNT(*) AS total_projects FROM projects');

    const [projByStatus] = await conn.query(`
      SELECT COALESCE(s.name,'Unknown') AS status, COUNT(*) AS cnt
      FROM projects p
      LEFT JOIN statuses s ON s.id = p.status_id
      GROUP BY status ORDER BY cnt DESC
    `);

    const [pending] = await conn.query(`
      SELECT COUNT(*) AS cnt, COALESCE(SUM(${moneyExpr()}),0) AS amount
      FROM project_terms pt
      JOIN projects p ON p.id=pt.project_id
      LEFT JOIN statuses s ON s.id = pt.term_status_id
      WHERE COALESCE(s.name,'Planned') NOT IN ${NOT_PAID}
    `);

    const [overdue] = await conn.query(`
      SELECT COUNT(*) AS cnt, COALESCE(SUM(${moneyExpr()}),0) AS amount
      FROM project_terms pt
      JOIN projects p ON p.id=pt.project_id
      LEFT JOIN statuses s ON s.id = pt.term_status_id
      WHERE COALESCE(s.name,'Planned') NOT IN ${NOT_PAID}
        AND pt.due_date IS NOT NULL AND pt.due_date < CURDATE()
    `);

    conn.release();
    res.json({ total_projects, projByStatus, pending: pending[0], overdue: overdue[0] });
  }catch(err){ next(err); }
}

export async function projectsByStatus(req,res,next){
  try{
    const [rows] = await pool.query(`
      SELECT COALESCE(s.name,'Unknown') AS status, COUNT(*) AS cnt
      FROM projects p LEFT JOIN statuses s ON s.id=p.status_id
      GROUP BY status ORDER BY cnt DESC
    `);
    res.json(rows);
  }catch(err){ next(err); }
}

export async function termsByStatus(req,res,next){
  try{
    const [rows] = await pool.query(`
      SELECT COALESCE(s.name,'Unknown') AS status,
             COUNT(*) AS cnt,
             COALESCE(SUM(${moneyExpr()}),0) AS amount
      FROM project_terms pt
      JOIN projects p ON p.id=pt.project_id
      LEFT JOIN statuses s ON s.id=pt.term_status_id
      GROUP BY status ORDER BY cnt DESC
    `);
    res.json(rows);
  }catch(err){ next(err); }
}

export async function upcomingTerms(req,res,next){
  const limit = Math.min(Number(req.query.limit||15), 100);
  try{
    const [rows] = await pool.query(`
      SELECT pt.id, p.name AS project_name, c.name AS customer_name,
             pt.percentage, p.contract_value,
             ${moneyExpr()} AS amount,
             pt.description, pt.due_date,
             COALESCE(s.name,'Planned') AS status
      FROM project_terms pt
      JOIN projects p ON p.id=pt.project_id
      LEFT JOIN customers c ON c.id=p.customer_id
      LEFT JOIN statuses s ON s.id=pt.term_status_id
      WHERE COALESCE(s.name,'Planned') NOT IN ${NOT_PAID}
        AND pt.due_date IS NOT NULL
      ORDER BY pt.due_date ASC
      LIMIT ?
    `, [limit]);
    res.json(rows);
  }catch(err){ next(err); }
}
JS

# dashboard routes
cat > src/routes/dashboard.js <<'JS'
import { Router } from 'express';
import { summary, projectsByStatus, termsByStatus, upcomingTerms } from '../controllers/dashboardController.js';
import { authMiddleware } from '../middleware/auth.js';
const r = Router();
r.use(authMiddleware);
r.get('/summary', summary);
r.get('/projects/by-status', projectsByStatus);
r.get('/terms/by-status', termsByStatus);
r.get('/terms/upcoming', upcomingTerms);
export default r;
JS

# import controller
cat > src/controllers/importController.js <<'JS'
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
JS

# import routes
cat > src/routes/importExcel.js <<'JS'
import { Router } from 'express';
import multer from 'multer';
import { template, importExcel } from '../controllers/importController.js';
import { authMiddleware } from '../middleware/auth.js';

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 25 * 1024 * 1024 }});
const r = Router();

r.use(authMiddleware);
r.get('/template.xlsx', template);
r.post('/excel', upload.single('file'), importExcel);

export default r;
JS

# wire routes into server if not already
if ! grep -q "/api/dashboard" src/server.js; then
  sed -i "s#app.use('/api/config'.*#&\nimport dashboardRoutes from './routes/dashboard.js';\nimport importExcelRoutes from './routes/importExcel.js';\napp.use('/api/dashboard', dashboardRoutes);\napp.use('/api/import', importExcelRoutes);\n#" src/server.js
fi

########################################
# Frontend: pages & components
########################################
cd "$FRONT"
npm i react-chartjs-2 chart.js lucide-react

mkdir -p src/pages src/components

# Small components: KPI card + upcoming table
cat > src/components/StatsCard.jsx <<'JSX'
import React from 'react'
export default function StatsCard({title, value, sub}) {
  return (
    <div className="card p-3">
      <div className="text-muted small">{title}</div>
      <div className="fs-4 fw-bold">{value}</div>
      {sub ? <div className="text-muted small">{sub}</div> : null}
    </div>
  )
}
JSX

cat > src/components/UpcomingTermsTable.jsx <<'JSX'
import React from 'react'
export default function UpcomingTermsTable({rows}){
  return (
    <div className="card p-3">
      <div className="d-flex justify-content-between align-items-center mb-2">
        <h6 className="m-0">Upcoming payment terms</h6>
      </div>
      <div className="table-responsive">
        <table className="table align-middle">
          <thead>
            <tr>
              <th>Due</th><th>Project</th><th>Customer</th>
              <th className="text-end">% / Amount</th><th>Status</th>
            </tr>
          </thead>
          <tbody>
          {rows.map((r,i)=>(
            <tr key={i}>
              <td>{r.due_date?.slice(0,10)||''}</td>
              <td>{r.project_name}</td>
              <td>{r.customer_name||''}</td>
              <td className="text-end">{(r.percentage||0).toFixed(0)}% / {Number(r.amount||0).toLocaleString()}</td>
              <td>{r.status||'Planned'}</td>
            </tr>
          ))}
          {!rows.length && <tr><td colSpan="5" className="text-center text-muted py-4">No upcoming terms</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  )
}
JSX

# Home page with charts
cat > src/pages/Home.jsx <<'JSX'
import React, {useEffect, useState} from 'react'
import StatsCard from '../components/StatsCard'
import UpcomingTermsTable from '../components/UpcomingTermsTable'
import { Bar, Doughnut } from 'react-chartjs-2'
import { Chart as ChartJS, BarElement, CategoryScale, LinearScale, ArcElement, Tooltip, Legend } from 'chart.js'
ChartJS.register(BarElement, CategoryScale, LinearScale, ArcElement, Tooltip, Legend)

export default function Home(){
  const [summary,setSummary] = useState(null)
  const [upcoming,setUpcoming] = useState([])
  const [projByStatus,setPBS] = useState([])
  const [termByStatus,setTBS] = useState([])

  useEffect(()=>{
    fetch('/api/dashboard/summary').then(r=>r.json()).then(setSummary)
    fetch('/api/dashboard/terms/upcoming?limit=15').then(r=>r.json()).then(setUpcoming)
    fetch('/api/dashboard/projects/by-status').then(r=>r.json()).then(setPBS)
    fetch('/api/dashboard/terms/by-status').then(r=>r.json()).then(setTBS)
  },[])

  return (
    <div className="d-flex flex-column gap-3">
      <div className="row g-3">
        <div className="col-sm-3"><StatsCard title="Total projects" value={summary?.total_projects||0} /></div>
        <div className="col-sm-3"><StatsCard title="Pending terms" value={summary?.pending?.cnt||0} sub={`Amount ${Number(summary?.pending?.amount||0).toLocaleString()}`} /></div>
        <div className="col-sm-3"><StatsCard title="Overdue terms" value={summary?.overdue?.cnt||0} sub={`Amount ${Number(summary?.overdue?.amount||0).toLocaleString()}`} /></div>
        <div className="col-sm-3"></div>
      </div>

      <div className="row g-3">
        <div className="col-lg-6 card p-3">
          <h6 className="mb-2">Projects by status</h6>
          <Bar data={{
            labels: projByStatus.map(x=>x.status||'Unknown'),
            datasets:[{label:'Projects', data:projByStatus.map(x=>x.cnt)}]
          }} options={{plugins:{legend:{display:false}}}} />
        </div>
        <div className="col-lg-6 card p-3">
          <h6 className="mb-2">Term status</h6>
          <Doughnut data={{
            labels: termByStatus.map(x=>x.status||'Unknown'),
            datasets:[{label:'Terms', data:termByStatus.map(x=>x.cnt)}]
          }} options={{plugins:{legend:{position:'bottom'}}}} />
        </div>
      </div>

      <UpcomingTermsTable rows={upcoming} />
    </div>
  )
}
JSX

# Import page
cat > src/pages/Import.jsx <<'JSX'
import React, {useState} from 'react'

export default function ImportExcel(){
  const [file,setFile] = useState(null)
  const [busy,setBusy] = useState(false)
  const [result,setResult] = useState(null)
  function dlTemplate(){ window.open('/api/import/template.xlsx','_blank') }

  async function submit(e){
    e.preventDefault()
    if(!file) return
    setBusy(true); setResult(null)
    const fd = new FormData()
    fd.append('file', file)
    const r = await fetch('/api/import/excel',{method:'POST', body:fd})
    const out = await r.json()
    setBusy(false); setResult(out)
  }

  return (
    <div className="card p-3">
      <h5>Bulk Import</h5>
      <p className="text-muted">Use the provided Excel template. Tabs: Customers, Contacts, Projects, PaymentTerms, Lookups(Optional).</p>
      <div className="d-flex gap-2 mb-2">
        <button className="btn btn-outline-secondary btn-sm" onClick={dlTemplate}>Download template</button>
      </div>
      <form onSubmit={submit} className="d-flex gap-2 align-items-center">
        <input type="file" className="form-control" accept=".xlsx" onChange={e=>setFile(e.target.files?.[0]||null)} />
        <button className="btn btn-primary" disabled={!file||busy}>{busy?'Importing...':'Import'}</button>
      </form>
      {result && <pre className="mt-3 bg-light p-2 small" style={{whiteSpace:'pre-wrap'}}>{JSON.stringify(result,null,2)}</pre>}
    </div>
  )
}
JSX

# Wire routes (depends on your router file name)
if grep -q "react-router-dom" src/App.jsx 2>/dev/null; then
  sed -i '1s#^#import Home from "./pages/Home.jsx"\nimport ImportExcel from "./pages/Import.jsx"\n#' src/App.jsx
  sed -i 's#</Routes>#  <Route path="/home" element={<Home/>} />\n    <Route path="/import" element={<ImportExcel/>} />\n  </Routes>#' src/App.jsx
fi

# Build frontend
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

########################################
# Restart backend
########################################
cd "$BACK"
pkill -f "node src/server.js" 2>/dev/null || true
npm start >/dev/null 2>&1 &
echo "Home dashboard + Import endpoints/pages added."
