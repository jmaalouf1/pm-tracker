import { pool } from '../db.js';
import argon2 from 'argon2';

// Ensure we know the user's role; if token lacks role, read from DB
async function resolveRole(req) {
  if (req.user?.role) return req.user.role;
  if (req.user?.id) {
    const [[u]] = await pool.query('SELECT role FROM users WHERE id = ?', [req.user.id]);
    if (u?.role) {
      req.user.role = u.role;
      return u.role;
    }
  }
  return null;
}

async function requireAdmin(req, res, next) {
  try {
    const role = await resolveRole(req);
    if (role === 'super_admin' || role === 'pm_admin') return next();
    return res.status(403).json({ error: 'forbidden' });
  } catch (e) {
    next(e);
  }
}

export const UsersAdmin = {
  requireAdmin,

  async list(req, res) {
    const [rows] = await pool.query(
      `SELECT u.id, u.name, u.email, u.role,
              (SELECT COUNT(*) FROM user_customers uc WHERE uc.user_id = u.id) AS customers_count
         FROM users u
        ORDER BY u.id DESC`
    );
    res.json(rows);
  },

  async create(req, res) {
    const { name, email, password, role } = req.body || {};
    if (!name || !email || !password || !role) {
      return res.status(400).json({ error: 'name, email, password, role are required' });
    }
    if (!['super_admin','pm_admin','pm_user','finance'].includes(role)) {
      return res.status(400).json({ error: 'invalid role' });
    }
    const hash = await argon2.hash(password, { type: argon2.argon2id });
    try {
      const [r] = await pool.query(
        'INSERT INTO users (name, email, password_hash, role) VALUES (?,?,?,?)',
        [name, email, hash, role]
      );
      res.json({ id: r.insertId, ok: true });
    } catch (e) {
      if (e.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'email already exists' });
      throw e;
    }
  },

  async getAssignedCustomers(req, res) {
    const { id } = req.params;
    const [rows] = await pool.query(
      `SELECT uc.customer_id, c.name
         FROM user_customers uc
         JOIN customers c ON c.id = uc.customer_id
        WHERE uc.user_id = ?
        ORDER BY c.name`, [id]
    );
    res.json(rows);
  },

  // Replace all assignments with provided list (array of customer_id)
  async putAssignedCustomers(req, res) {
    const { id } = req.params;
    const { customer_ids } = req.body || {};
    if (!Array.isArray(customer_ids)) return res.status(400).json({ error: 'customer_ids array required' });

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      await conn.query('DELETE FROM user_customers WHERE user_id = ?', [id]);
      if (customer_ids.length) {
        const values = customer_ids.map(cid => [id, cid]);
        await conn.query('INSERT INTO user_customers (user_id, customer_id) VALUES ?', [values]);
      }
      await conn.commit();
    } catch (e) {
      await conn.rollback();
      throw e;
    } finally {
      conn.release();
    }
    res.json({ ok: true });
  },

  async updateRole(req, res) {
    const { id } = req.params;
    const { role } = req.body || {};
    if (!['super_admin','pm_admin','pm_user','finance'].includes(role)) {
      return res.status(400).json({ error: 'invalid role' });
    }
    await pool.query('UPDATE users SET role = ? WHERE id = ?', [role, id]);
    res.json({ ok: true });
  }
};
