import express from 'express';
import { CustomersController } from '../controllers/customersController.js';
import { authRequired } from '../middleware/auth.js';
import { requireRole } from '../middleware/auth.js';
import { Roles } from '../lib/rbac.js';

const router = express.Router();
router.use(authRequired);

// list/search + create/update
router.get('/', CustomersController.list);
router.get('/:id', CustomersController.get);
router.post('/', requireRole(Roles.SUPER, Roles.PM_ADMIN), CustomersController.create);
router.put('/:id', requireRole(Roles.SUPER, Roles.PM_ADMIN), CustomersController.update);

// contacts
router.post('/:id/contacts', requireRole(Roles.SUPER, Roles.PM_ADMIN), CustomersController.addContact);
router.put('/:id/contacts/:contactId', requireRole(Roles.SUPER, Roles.PM_ADMIN), CustomersController.updateContact);
router.delete('/:id/contacts/:contactId', requireRole(Roles.SUPER, Roles.PM_ADMIN), CustomersController.deleteContact);

export default router;
