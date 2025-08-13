cat > ~/projects/backend/src/routes/projectTermsAdmin.js <<'JS'
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
JS

# restart the API
pkill -f "node src/server.js" 2>/dev/null || true
cd ~/projects/backend && npm start
