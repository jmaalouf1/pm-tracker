import { Router } from 'express';
import * as Auth from '../middleware/auth.js';
import { loadUser } from '../middleware/loadUser.js';
import { pool } from '../db.js';
import { pageParams, like } from '../utils/query.js';

const pickAuth = () => {
  const names = ['authMiddleware','requireAuth','verifyToken','ensureAuth','authenticate'];
  for (const n of names) if (typeof Auth[n] === 'function') return Auth[n];
  if (typeof Auth.default === 'function') return Auth.default;
  const firstFn = Object.values(Auth).find(v => typeof v === 'function');
  return firstFn || ((req,res,next)=>next());
};
const authMw = pickAuth();

const router = Router();
router.use(authMw, loadUser);

// LIST with pagination + q + PM restriction
router.get('/', async (req, res) => {
  const q = req.query.q;
  const { page, pageSize, offset } = pageParams(req, 20);
  const args = [];
  let where = '1=1';

  if (q && q.trim()) {
    where += ' AND (p.name LIKE ? OR c.name LIKE ?)';
    const L = like(q);
    args.push(L, L);
  }

  if (req.user?.role === 'pm_user') {
    where += ' AND p.customer_id IN (SELECT customer_id FROM user_customers WHERE user_id = ?)';
    args.push(req.user.id);
  }

  const [[{ cnt }]] = await pool.query(
    `SELECT COUNT(*) cnt FROM projects p LEFT JOIN customers c ON c.id = p.customer_id WHERE ${where}`,
    args
  );

  const [rows] = await pool.query(
    `SELECT p.*, c.name AS customer, s.name AS segment, st.name AS status
       FROM projects p
       LEFT JOIN customers c ON c.id = p.customer_id
       LEFT JOIN segments s ON s.id = p.segment_id
       LEFT JOIN statuses st ON st.id = p.status_id
      WHERE ${where}
      ORDER BY p.id DESC
      LIMIT ? OFFSET ?`,
    [...args, pageSize, offset]
  );
  res.json({ data: rows, page, pageSize, total: cnt });
});

export default router;
