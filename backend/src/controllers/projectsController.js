import { pool } from '../db.js';

function buildFilters(q) {
  const where = [];
  const params = [];
  if (q.search) {
    where.push('(p.name LIKE ? OR c.name LIKE ? OR s.name LIKE ? OR sl.name LIKE ? OR pr.name LIKE ?)');
    for (let i = 0; i < 5; i++) params.push(`%${q.search}%`);
  }
  if (q.status_id) { where.push('p.status_id = ?'); params.push(q.status_id); }
  if (q.customer_id) { where.push('p.customer_id = ?'); params.push(q.customer_id); }
  return { where: where.length ? 'WHERE ' + where.join(' AND ') : '', params };
}

export const ProjectsController = {
  async list(req, res) {
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const pageSize = Math.min(100, Math.max(1, parseInt(req.query.pageSize || '20')));
    const { where, params } = buildFilters(req.query);
    const offset = (page - 1) * pageSize;
    const [rows] = await pool.query(
      `SELECT p.*, c.name AS customer, s.name AS segment, sl.name AS service_line, pr.name AS partner, pt.name AS payment_term, st.name AS status, inv.name AS invoice_status, po.name AS po_status
       FROM projects p
       LEFT JOIN customers c ON p.customer_id = c.id
       LEFT JOIN segments s ON p.segment_id = s.id
       LEFT JOIN service_lines sl ON p.service_line_id = sl.id
       LEFT JOIN partners pr ON p.partner_id = pr.id
       LEFT JOIN payment_terms pt ON p.payment_term_id = pt.id
       LEFT JOIN statuses st ON p.status_id = st.id
       LEFT JOIN statuses inv ON p.invoice_status_id = inv.id
       LEFT JOIN statuses po ON p.po_status_id = po.id
       ${where}
       ORDER BY p.id DESC
       LIMIT ? OFFSET ?`, [...params, pageSize, offset]
    );
    const [[{ total }]] = await pool.query(`SELECT COUNT(*) AS total FROM projects p ${where}`, params);
    res.json({ data: rows, page, pageSize, total });
  },
  async get(req, res) {
    const { id } = req.params;
    const [[row]] = await pool.query('SELECT * FROM projects WHERE id = ?', [id]);
    if (!row) return res.status(404).json({ error: 'Not found' });
    res.json(row);
  },
  async create(req, res) {
    const {
      name, customer_id, segment_id, service_line_id, partner_id, payment_term_id,
      status_id, po_status_id, invoice_status_id, backlog_2025
    } = req.body || {};
    if (!name) return res.status(400).json({ error: 'name required' });
    const [r] = await pool.query(
      `INSERT INTO projects (name, customer_id, segment_id, service_line_id, partner_id, payment_term_id, status_id, po_status_id, invoice_status_id, backlog_2025, created_by)
       VALUES (?,?,?,?,?,?,?,?,?,?,?)`,
      [name, customer_id || null, segment_id || null, service_line_id || null, partner_id || null, payment_term_id || null,
       status_id || null, po_status_id || null, invoice_status_id || null, backlog_2025 || 0, req.user?.id || null]
    );
    res.status(201).json({ id: r.insertId });
  },
  async update(req, res) {
    const { id } = req.params;
    const fields = ['name','customer_id','segment_id','service_line_id','partner_id','payment_term_id','status_id','po_status_id','invoice_status_id','backlog_2025'];
    const sets = [];
    const params = [];
    for (const f of fields) {
      if (req.body[f] !== undefined) { sets.push(`${f} = ?`); params.push(req.body[f]); }
    }
    if (!sets.length) return res.status(400).json({ error: 'No changes' });
    params.push(id);
    const [r] = await pool.query(`UPDATE projects SET ${sets.join(', ')} WHERE id = ?`, params);
    res.json({ affected: r.affectedRows });
  },
  async financePatch(req, res) {
    const { id } = req.params;
    // Only allow finance fields
    const allowed = ['invoice_status_id','po_status_id'];
    const sets = [];
    const params = [];
    for (const f of allowed) {
      if (req.body[f] !== undefined) { sets.push(`${f} = ?`); params.push(req.body[f]); }
    }
    if (!sets.length) return res.status(400).json({ error: 'No finance changes' });
    params.push(id);
    const [r] = await pool.query(`UPDATE projects SET ${sets.join(', ')} WHERE id = ?`, params);
    res.json({ affected: r.affectedRows });
  }
};
