import { pool } from '../db.js';

export const PaymentTermsController = {
  async list(req, res) {
    const [rows] = await pool.query('SELECT * FROM payment_terms ORDER BY days, name');
    res.json(rows);
  },
  async create(req, res) {
    const { name, days, description } = req.body || {};
    if (!name) return res.status(400).json({ error: 'name required' });
    const [r] = await pool.query('INSERT INTO payment_terms (name,days,description) VALUES (?,?,?)', [name, days || 0, description || null]);
    res.status(201).json({ id: r.insertId });
  },
  async update(req, res) {
    const { id } = req.params;
    const { name, days, description } = req.body || {};
    const [r] = await pool.query('UPDATE payment_terms SET name = COALESCE(?, name), days = COALESCE(?, days), description = COALESCE(?, description) WHERE id = ?', [name, days, description, id]);
    res.json({ affected: r.affectedRows });
  },
  async remove(req, res) {
    const { id } = req.params;
    await pool.query('DELETE FROM payment_terms WHERE id = ?', [id]);
    res.status(204).send();
  }
};
