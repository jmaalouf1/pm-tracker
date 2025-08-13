import { pool } from '../db.js';

/** Ensure req.user has role (and stays current if the role changed in DB) */
export async function loadUser(req, res, next) {
  try {
    if (!req.user?.id) return next();  // not logged in or auth not attached
    const [[u]] = await pool.query('SELECT id, name, email, role FROM users WHERE id = ?', [req.user.id]);
    if (u) req.user = u; // normalize to {id,name,email,role}
    next();
  } catch (e) {
    next(e);
  }
}
