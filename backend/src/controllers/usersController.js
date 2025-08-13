import { pool } from '../db.js';
import argon2 from 'argon2';

export const UsersController = {
  async list(req, res) {
    const [rows] = await pool.query('SELECT id,name,email,role,created_at FROM users ORDER BY id DESC');
    res.json(rows);
  },
  async create(req, res) {
    const { name, email, password, role } = req.body || {};
    if (!name || !email || !password) return res.status(400).json({ error: 'Missing fields' });
    const hash = await argon2.hash(password);
    try {
      const [r] = await pool.query('INSERT INTO users (name,email,password_hash,role) VALUES (?,?,?,?)', [name, email, hash, role || 'pm_user']);
      res.status(201).json({ id: r.insertId });
    } catch (e) {
      if (e.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Email already exists' });
      throw e;
    }
  }
};
