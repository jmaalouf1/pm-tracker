import { pool } from '../db.js';

export async function searchTerms(req, res) {
  const { project_id, customer_id, status_id, q } = req.query || {};
  const where = ['1=1'];
  const args = [];
  if (project_id) { where.push('t.project_id = ?'); args.push(project_id); }
  if (customer_id) { where.push('p.customer_id = ?'); args.push(customer_id); }
  if (status_id) { where.push('t.status_id = ?'); args.push(status_id); }
  if (q && q.trim()) { where.push('t.description LIKE ?'); args.push(`%${q.trim()}%`); }

  // PM restriction
  if (req.user?.role === 'pm_user') {
    where.push('p.customer_id IN (SELECT customer_id FROM user_customers WHERE user_id = ?)');
    args.push(req.user.id);
  }

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
  // Check PM access by resolving customer
  const [[row]] = await pool.query(
    `SELECT p.customer_id FROM project_terms t JOIN projects p ON p.id = t.project_id WHERE t.id = ?`,
    [id]
  );
  if (!row) return res.status(404).json({ error: 'not found' });
  if (req.user?.role === 'pm_user') {
    const [[allowed]] = await pool.query(
      'SELECT 1 FROM user_customers WHERE user_id = ? AND customer_id = ?',
      [req.user.id, row.customer_id]
    );
    if (!allowed) return res.status(403).json({ error: 'forbidden' });
  }
  const { status_id } = req.body || {};
  await pool.query('UPDATE project_terms SET status_id = ?, updated_at = NOW() WHERE id = ?', [status_id || null, id]);
  res.json({ ok: true });
}
