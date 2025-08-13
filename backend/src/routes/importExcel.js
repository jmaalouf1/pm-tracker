import { Router } from 'express';
import multer from 'multer';
import { template, importExcel } from '../controllers/importController.js';
import authMw from '../middleware/authBridge.js';

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 25 * 1024 * 1024 } });

const r = Router();
r.use(authMw);
r.get('/template.xlsx', template);
r.post('/excel', upload.single('file'), importExcel);

export default r;
