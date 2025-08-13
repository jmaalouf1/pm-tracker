import { pool } from '../db.js';

export async function searchTerms(req, res) {
  const { project_id, customer_id, status_id, q } = req.query || {};
  const where = ['1=1'];
  const args = [];
  if (project_id) { where.push('t.project_id = ?'); args.push(project_id); }
  if (customer_id) { where.push('p.customer_id = ?'); args.push(customer_id); }
  if (status_id) { where.push('t.status_id = ?'); args.push(status_id); }
  if (q && q.trim()) { where.push('t.description LIKE ?'); args.push(`%${q.trim()}%`); }

  const [rows] = await pool.query(
    `SELECT t.*, p.name AS project_name, c.name AS customer_name
       FROM project_terms t
       JOIN projects p ON p.id = t.project_id
       LEFT JOIN customers c ON c.id = p.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY t.project_id, t.seq, t.id`,
    args
  );
  res.json(rows);
}

export async function updateTermStatus(req, res) {
  const { id } = req.params;
  const { status_id } = req.body || {};
  await pool.query('UPDATE project_terms SET status_id = ?, updated_at = NOW() WHERE id = ?', [status_id || null, id]);
  res.json({ ok: true });
}
