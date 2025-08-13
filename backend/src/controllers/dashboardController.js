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
