const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/authMiddleware');

// GET all customers
router.get('/', verifyToken, async (req, res) => {
  try {
    const [customers] = await db.query('SELECT * FROM customers');
    res.json(customers);
  } catch (err) {
    console.error('Error fetching customers:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET a specific customer by ID
router.get('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await db.query('SELECT * FROM customers WHERE id = ?', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    res.json(rows[0]);
  } catch (err) {
    console.error('Error fetching customer:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// CREATE new customer
router.post('/', verifyToken, async (req, res) => {
  const {
    name,
    country,
    institution_type,
    registration_number,
    contacts
  } = req.body;

  const created_by = req.user.id;

  try {
    const [result] = await db.execute(
      `
      INSERT INTO customers (
        name, country, institution_type, registration_number, contacts, created_by
      ) VALUES (?, ?, ?, ?, ?, ?)
      `,
      [name, country, institution_type, registration_number, contacts, created_by]
    );

    res.status(201).json({ message: 'Customer created', customer_id: result.insertId });
  } catch (err) {
    console.error('Error creating customer:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// UPDATE customer
router.put('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;
  const {
    name,
    country,
    institution_type,
    registration_number,
    contacts
  } = req.body;

  try {
    const [result] = await db.execute(
      `
      UPDATE customers SET
        name = ?, country = ?, institution_type = ?, registration_number = ?, contacts = ?, updated_at = NOW()
      WHERE id = ?
      `,
      [name, country, institution_type, registration_number, contacts, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    res.json({ message: 'Customer updated' });
  } catch (err) {
    console.error('Error updating customer:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// DELETE customer
router.delete('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;
  try {
    const [result] = await db.execute('DELETE FROM customers WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    res.json({ message: 'Customer deleted' });
  } catch (err) {
    console.error('Error deleting customer:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;

