// backend/db.js (ESM + dotenv loaded here)
import 'dotenv/config'; // try global .env first

// Extra safety: explicitly load backend/.env relative to this file
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as dotenv from 'dotenv';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '.env') }); // no-op if already loaded

import mysql from 'mysql2/promise';

// --- TEMP sanity log: shows whether password is present (remove after) ---
if (!process.env.DB_PASS) {
  console.warn('[DB] DB_PASS is missing at pool init!');
} else {
  console.log('[DB] DB_PASS loaded (length):', String(process.env.DB_PASS).length);
}

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  user: process.env.DB_USER || 'appuser',
  database: process.env.DB_NAME || 'pmtracker',
  password: process.env.DB_PASS || undefined, // will be defined if .env loaded
  port: Number(process.env.DB_PORT || 3306),
  waitForConnections: true,
  connectionLimit: 10,
  namedPlaceholders: true,
});

export default pool;
export { pool };
