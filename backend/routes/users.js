// backend/routes/users.js

const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken, isSuperAdmin } = require('../middleware/authMiddleware');

// GET all users (only accessible by super_admin)
router.get('/', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const [users] = await db.query('SELECT id, username, email, role, active, created_at FROM users');
    res.json(users);
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// PUT /users/:id/status - activate/deactivate a user (only by super_admin)
router.put('/:id/status', verifyToken, isSuperAdmin, async (req, res) => {
  const { active } = req.body;
  const { id } = req.params;

  try {
    await db.execute('UPDATE users SET active = ? WHERE id = ?', [active, id]);
    res.json({ message: 'User status updated' });
  } catch (err) {
    console.error('Error updating user status:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

router.post('/', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { username, email, password, role = 'pm_user', active = 1 } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'username, email, password required' });
    }
    const password_hash = await bcrypt.hash(password, 10);
    await db.execute(
      'INSERT INTO users (id, username, email, password_hash, role, active) VALUES (UUID(),?,?,?,?,?)',
      [username, email, password_hash, role, active]
    );
    res.status(201).json({ message: 'User created' });
  } catch (err) {
    console.error('Error creating user:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;

