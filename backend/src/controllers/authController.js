import { pool } from '../db.js';
import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import crypto from 'crypto';

function signAccess(user) {
  return jwt.sign({ id: user.id, role: user.role, name: user.name, email: user.email }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
}
function signRefresh(user) {
  return jwt.sign({ id: user.id }, config.refreshSecret, { expiresIn: config.refreshExpiresIn });
}
async function storeRefresh(userId, token, ua, ip) {
  const hash = crypto.createHash('sha256').update(token).digest('hex');
  const [rows] = await pool.query('INSERT INTO refresh_tokens (user_id, token_hash, user_agent, ip, expires_at) VALUES (?,?,?,?, DATE_ADD(NOW(), INTERVAL 30 DAY))', [userId, hash, ua || null, ip || null]);
  return rows.insertId;
}
async function revokeRefresh(token) {
  const hash = crypto.createHash('sha256').update(token).digest('hex');
  await pool.query('UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = ?', [hash]);
}

export const AuthController = {
  async login(req, res) {
    const { email, password } = req.body || {};
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' });
    const [[user]] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const ok = await argon2.verify(user.password_hash, password);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
    const accessToken = signAccess(user);
    const refreshToken = signRefresh(user);
    await storeRefresh(user.id, refreshToken, req.headers['user-agent'], req.ip);
    return res.json({ accessToken, refreshToken, user: { id: user.id, name: user.name, email: user.email, role: user.role } });
  },
  async refresh(req, res) {
    const { refreshToken } = req.body || {};
    if (!refreshToken) return res.status(400).json({ error: 'Missing refreshToken' });
    try {
      const payload = jwt.verify(refreshToken, config.refreshSecret);
      const accessToken = signAccess({ id: payload.id, role: payload.role || 'pm_user', name: payload.name, email: payload.email });
      return res.json({ accessToken });
    } catch (e) {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }
  },
  async logout(req, res) {
    const { refreshToken } = req.body || {};
    if (refreshToken) await revokeRefresh(refreshToken);
    return res.status(204).send();
  }
};
