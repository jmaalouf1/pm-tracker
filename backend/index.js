/**
 * Project Tracker Backend - Flat Code Bundle
 * Tech Stack: Node.js, Express.js, MySQL (Cloud SQL compatible), JWT, dotenv
 */

// index.js
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const dotenv = require('dotenv');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const projectRoutes = require('./routes/projects');
const customerRoutes = require('./routes/customers');		
const configRoutes = require('./routes/config');
const { verifyToken } = require('./middleware/authMiddleware');
const db = require('./db');

dotenv.config();

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.use('/auth', authRoutes);
app.use('/users', verifyToken, userRoutes);
app.use('/projects', verifyToken, projectRoutes);
app.use('/config', configRoutes);
app.use('/customers', customerRoutes);

const PORT = process.env.PORT || 8080;
(async () => {
  try {
    const conn = await db.getConnection();
    console.log('✅ Connected to MySQL');
    conn.release();
    app.listen(PORT, () => console.log(`Listening on port ${PORT}`));
  } catch (err) {
    console.error('❌ DB connection failed:', err);
    process.exit(1);
  }
})();

