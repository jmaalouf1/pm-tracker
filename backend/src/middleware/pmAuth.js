import { pool } from '../db.js';

export async function canAccessCustomer(req, res, next) {
  try {
    const user = req.user;
    if (!user) return res.status(401).json({ error: 'unauthorized' });
    if (['super_admin','pm_admin','finance'].includes(user.role)) return next();

    if (user.role === 'pm_user') {
      let customerId = req.body?.customer_id;
      if (!customerId && req.params?.projectId) {
        const [[row]] = await pool.query('SELECT customer_id FROM projects WHERE id = ?', [req.params.projectId]);
        customerId = row?.customer_id;
      }
      if (!customerId) return res.status(400).json({ error: 'customer_id required' });
      const [[allowed]] = await pool.query(
        'SELECT 1 FROM user_customers WHERE user_id = ? AND customer_id = ?',
        [user.id, customerId]
      );
      if (!allowed) return res.status(403).json({ error: 'forbidden: customer not assigned to PM' });
    }
    next();
  } catch (e) { next(e); }
}
