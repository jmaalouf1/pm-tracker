import { createPool } from 'mysql2/promise';
import 'dotenv/config';
import argon2 from 'argon2';

const pool = createPool({
  host: process.env.DB_HOST || 'localhost',
  port: +(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'pm_tracker'
});

async function run() {
  const conn = await pool.getConnection();
  try {
    // Seed statuses
    const statuses = [
      ['project_status','New'], ['project_status','In Progress'], ['project_status','On Hold'], ['project_status','Completed'],
      ['invoice_status','Not Invoiced'], ['invoice_status','Partially Invoiced'], ['invoice_status','Fully Invoiced'],
      ['po_status','Not Issued'], ['po_status','Issued'], ['po_status','Closed']
    ];
    for (const [type, name] of statuses) {
      await conn.query('INSERT IGNORE INTO statuses (type,name) VALUES (?,?)', [type, name]);
    }
    // Seed default admin
    const hash = await argon2.hash('Admin@12345');
    await conn.query(
      'INSERT IGNORE INTO users (id,name,email,password_hash,role) VALUES (1,?,?,?,?)',
      ['Super Admin', 'admin@example.com', hash, 'super_admin']
    );
    console.log('Seeded statuses and super admin (admin@example.com / Admin@12345).');
  } finally {
    conn.release();
    await pool.end();
  }
}

run().catch(err => { console.error(err); process.exit(1); });
