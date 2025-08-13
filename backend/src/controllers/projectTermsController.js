import { pool } from '../db.js';

async function ensureProject(id) {
  const [[p]] = await pool.query('SELECT id FROM projects WHERE id = ?', [id]);
  return !!p;
}

export const ProjectTermsController = {
  async list(req, res) {
    const { id } = req.params;
    if (!(await ensureProject(id))) return res.status(404).json({ error: 'Project not found' });
    const [rows] = await pool.query(
      `SELECT t.*, s.name AS status
         FROM project_terms t
         LEFT JOIN statuses s ON s.id = t.status_id
        WHERE t.project_id = ?
        ORDER BY t.seq, t.id`, [id]);
    res.json(rows);
  },
  async replaceAll(req, res) {
    const { id } = req.params;
    const { terms } = req.body || {};
    if (!Array.isArray(terms) || !terms.length) return res.status(400).json({ error: 'terms array required' });
    let sum = 0;
    for (const t of terms) {
      const pct = Number(t.percentage);
      if (!(pct >= 0 && pct <= 100)) return res.status(400).json({ error: 'percentage must be between 0 and 100' });
      if (!t.description || !String(t.description).trim()) return res.status(400).json({ error: 'description required for each term' });
      sum += pct;
    }
    // floating tolerance 3 decimals
    if (Math.abs(sum - 100) > 0.01) return res.status(400).json({ error: 'Sum of percentages must equal 100%' });

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      await conn.query('DELETE FROM project_terms WHERE project_id = ?', [id]);
      let seq = 1;
      for (const t of terms) {
        await conn.query(
          'INSERT INTO project_terms (project_id, seq, percentage, description, status_id) VALUES (?,?,?,?,?)',
          [id, seq++, Number(t.percentage), t.description, t.status_id || null]
        );
      }
      await conn.commit();
    } catch (e) {
      await conn.rollback();
      throw e;
    } finally {
      conn.release();
    }
    res.json({ ok: true });
  }
};
