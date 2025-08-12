import { createPool } from 'mysql2/promise';
import fs from 'fs';
import path from 'path';
import 'dotenv/config';

const pool = createPool({
  host: process.env.DB_HOST || 'localhost',
  port: +(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'pm_tracker',
  multipleStatements: true
});

async function run() {
  const file = path.join(process.cwd(), 'db', 'migrations', '001_init.sql');
  const sql = fs.readFileSync(file, 'utf8');
  const conn = await pool.getConnection();
  try {
    await conn.query(sql);
    console.log('Migration 001 applied.');
  } finally {
    conn.release();
    await pool.end();
  }
}

run().catch(err => { console.error(err); process.exit(1); });
