import { Router } from 'express';
import * as Auth from '../middleware/auth.js';
import { loadUser } from '../middleware/loadUser.js';
import { searchTerms, updateTermStatus } from '../controllers/projectTermsAdminController.js';

const pickAuth = () => {
  const names = ['authMiddleware','requireAuth','verifyToken','ensureAuth','authenticate'];
  for (const n of names) if (typeof Auth[n] === 'function') return Auth[n];
  if (typeof Auth.default === 'function') return Auth.default;
  const firstFn = Object.values(Auth).find(v => typeof v === 'function');
  return firstFn || ((req,res,next)=>next());
};
const authMw = pickAuth();

const r = Router();
r.use(authMw, loadUser);
r.get('/', searchTerms);
r.patch('/:id', updateTermStatus);
export default r;
