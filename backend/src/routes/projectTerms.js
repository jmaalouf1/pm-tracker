import express from 'express';
import { ProjectTermsController } from '../controllers/projectTermsController.js';
import { authRequired } from '../middleware/auth.js';
import { requireRole } from '../middleware/auth.js';
import { Roles } from '../lib/rbac.js';

const router = express.Router({ mergeParams: true });
router.use(authRequired);

router.get('/', ProjectTermsController.list);
router.put('/', requireRole(Roles.SUPER, Roles.PM_ADMIN, Roles.PM_USER), ProjectTermsController.replaceAll);

export default router;
