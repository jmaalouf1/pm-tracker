// backend/routes/paymentTerms.js
const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken } = require('../middleware/authMiddleware');

// Get all payment terms for a project
router.get('/', verifyToken, async (req, res) => {
  const { project_id } = req.query;
  if (!project_id) return res.status(400).json({ message: 'project_id is required' });

  try {
    const [rows] = await db.query(
      `SELECT pt.*, ps.label AS status_label
       FROM payment_terms pt
       LEFT JOIN payment_statuses ps ON pt.status_id = ps.id
       WHERE pt.project_id = ?
       ORDER BY pt.id`,
      [project_id]
    );
    res.json(rows);
  } catch (err) {
    console.error('Error fetching payment terms:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Create payment term
router.post('/', verifyToken, async (req, res) => {
  const { project_id, label, percent, amount, status_id, due_date, notes } = req.body;
  if (!project_id || !label) {
    return res.status(400).json({ message: 'project_id and label are required' });
  }

  try {
    let computedAmount = amount;
    if (percent && !amount) {
      const [[proj]] = await db.query('SELECT total_amount FROM projects WHERE id = ?', [project_id]);
      if (proj && proj.total_amount != null) {
        computedAmount = Math.round((proj.total_amount * percent / 100) * 100) / 100;
      }
    }

    const [result] = await db.query(
      `INSERT INTO payment_terms (project_id, label, percent, amount, status_id, due_date, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [project_id, label, percent ?? null, computedAmount ?? null, status_id ?? null, due_date ?? null, notes ?? null]
    );

    res.status(201).json({ id: result.insertId, message: 'Payment term created' });
  } catch (err) {
    console.error('Error creating payment term:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Update payment term
router.put('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;
  const { label, percent, amount, status_id, due_date, notes } = req.body;

  try {
    const [result] = await db.query(
      `UPDATE payment_terms
       SET label = ?, percent = ?, amount = ?, status_id = ?, due_date = ?, notes = ?
       WHERE id = ?`,
      [label ?? null, percent ?? null, amount ?? null, status_id ?? null, due_date ?? null, notes ?? null, id]
    );

    if (!result.affectedRows) return res.status(404).json({ message: 'Payment term not found' });
    res.json({ message: 'Payment term updated' });
  } catch (err) {
    console.error('Error updating payment term:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Delete payment term
router.delete('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;

  try {
    const [result] = await db.query('DELETE FROM payment_terms WHERE id = ?', [id]);
    if (!result.affectedRows) return res.status(404).json({ message: 'Payment term not found' });
    res.json({ message: 'Payment term deleted' });
  } catch (err) {
    console.error('Error deleting payment term:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;

