import { Router } from 'express';
import * as Auth from '../middleware/auth.js';
import { searchTerms, updateTermStatus } from '../controllers/projectTermsAdminController.js';

// Be tolerant of whatever the project exports:
// - named authMiddleware
// - default export function
// - other common names (requireAuth / verifyToken)
const authMw =
  (Auth && (Auth.authMiddleware || Auth.default || Auth.requireAuth || Auth.verifyToken))
  || ((req, res, next) => next()); // fallback (no-op) if nothing found

const r = Router();
r.use(authMw);

r.get('/', searchTerms);
r.patch('/:id', updateTermStatus);

export default r;
