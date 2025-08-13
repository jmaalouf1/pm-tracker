// backend/routes/config.js
const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/authMiddleware');

/**
 * GET /config/customers
 * Optional ?q=partial&limit=10 for autocomplete.
 */
router.get('/customers', verifyToken, async (req, res) => {
  try {
    const q = (req.query.q || '').trim();
    const limit = Math.min(parseInt(req.query.limit || '20', 10), 100);

    if (q) {
      const [rows] = await db.execute(
        `SELECT id, name, country, institution_type
         FROM customers
         WHERE name LIKE ? OR CAST(id AS CHAR) LIKE ?
         ORDER BY name
         LIMIT ?`,
        [`%${q}%`, `%${q}%`, limit]
      );
      return res.json(rows);
    }

    const [rows] = await db.execute(
      `SELECT id, name, country, institution_type
       FROM customers
       ORDER BY name
       LIMIT ?`,
      [limit]
    );
    res.json(rows);
  } catch (err) {
    console.error('Error fetching customers:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

/**
 * GET /config/payment-statuses
 * For <select> options when building payment terms
 */
router.get('/payment-statuses', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, label FROM payment_statuses ORDER BY label'
    );
    res.json(rows);
  } catch (e) {
    console.error('get payment-statuses error', e);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;

