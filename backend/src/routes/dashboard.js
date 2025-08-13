import { Router } from 'express';
import { summary, projectsByStatus, termsByStatus, upcomingTerms } from '../controllers/dashboardController.js';
import authMw from '../middleware/authBridge.js';

const r = Router();
r.use(authMw);

r.get('/summary', summary);
r.get('/projects/by-status', projectsByStatus);
r.get('/terms/by-status', termsByStatus);
r.get('/terms/upcoming', upcomingTerms);

export default r;
