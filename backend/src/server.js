import 'dotenv/config'; 
import express from 'express';
import usersAdminRoutes from './routes/usersAdmin.js';
import projectTermsAdminRoutes from './routes/projectTermsAdmin.js';
import helmet from 'helmet';
import cors from 'cors';
import pinoHttp from 'pino-http';
import { config } from './config.js';
import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';
import projectRoutes from './routes/projects.js';
import paymentTermRoutes from './routes/paymentTerms.js';
import configRoutes from './routes/config.js';
import customerRoutes from './routes/customers.js';
import projectTermsRoutes from './routes/projectTerms.js';


const app = express();
app.use(helmet());
app.use(cors({ origin: config.corsOrigin, credentials: true }));
app.use(express.json());
app.use(pinoHttp());

app.get('/api/health', (req, res) => res.json({ ok: true }));
app.use('/api/auth', authRoutes);
app.use('/api/users', usersAdminRoutes);
app.use('/api/project-terms', projectTermsAdminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/payment-terms', paymentTermRoutes);
app.use('/api/config', configRoutes);
import dashboardRoutes from './routes/dashboard.js';
import importExcelRoutes from './routes/importExcel.js';
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/import', importExcelRoutes);

app.use('/api/customers', customerRoutes);
app.use('/api/projects/:id/terms', projectTermsRoutes);

app.use((err, req, res, next) => {
  req.log?.error(err);
  res.status(500).json({ error: 'Internal Server Error' });
});

app.listen(config.port, () => {
  console.log(`API listening on :${config.port}`);
});
