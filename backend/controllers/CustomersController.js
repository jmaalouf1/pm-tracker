// backend/src/controllers/customersController.js
import pool from '../../db.js';

export const Customers = {
  async list(req, res) {
    // optional q = name, CR or VAT contains
    const q = (req.query.q || '').trim();
    const params = [];
    let where = '';
    if (q) {
      where = `WHERE c.name LIKE ? OR c.cr LIKE ? OR c.vat LIKE ?`;
      const like = `%${q}%`;
      params.push(like, like, like);
    }

    // Return basic fields; extend as needed
    const sql = `
      SELECT c.id, c.name, c.country, c.type, c.cr, c.vat
      FROM customers c
      ${where}
      ORDER BY c.name ASC
      LIMIT 200
    `;
    const [rows] = await pool.query(sql, params);
    res.json({ items: rows });
  },

  async create(req, res) {
    const { name, country, type, cr, vat } = req.body || {};
    if (!name) return res.status(400).json({ message: 'name is required' });

    const sql = `
      INSERT INTO customers (name, country, type, cr, vat, is_active)
      VALUES (?,?,?,?,?,1)
    `;
    const [r] = await pool.query(sql, [name, country || null, type || null, cr || null, vat || null]);
    res.status(201).json({ id: r.insertId });
  },
};
