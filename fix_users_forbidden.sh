set -euo pipefail
BACK=~/projects/backend

detect_auth() {
  local f="$BACK/src/middleware/auth.js"
  if ! test -f "$f"; then
    echo "ERROR: $f not found" >&2; exit 1
  fi
  # Try to detect a common export symbol
  if grep -q "export default" "$f"; then echo "default"; exit 0; fi
  for n in authMiddleware requireAuth verifyToken ensureAuth; do
    if grep -q "export const $n" "$f" || grep -q "export function $n" "$f"; then
      echo "$n"; exit 0
    fi
  done
  # last resort: assume default
  echo "default"
}

AUTH_EXPORT=$(detect_auth)
echo "Detected auth export: $AUTH_EXPORT"

# ---- Users Admin controller: resolve role from DB if missing ----
cat > "$BACK/src/controllers/usersAdminController.js" <<'JS'
import { pool } from '../db.js';
import argon2 from 'argon2';

// Ensure we know the user's role; if token lacks role, read from DB
async function resolveRole(req) {
  if (req.user?.role) return req.user.role;
  if (req.user?.id) {
    const [[u]] = await pool.query('SELECT role FROM users WHERE id = ?', [req.user.id]);
    if (u?.role) {
      req.user.role = u.role;
      return u.role;
    }
  }
  return null;
}

async function requireAdmin(req, res, next) {
  try {
    const role = await resolveRole(req);
    if (role === 'super_admin' || role === 'pm_admin') return next();
    return res.status(403).json({ error: 'forbidden' });
  } catch (e) {
    next(e);
  }
}

export const UsersAdmin = {
  requireAdmin,

  async list(req, res) {
    const [rows] = await pool.query(
      `SELECT u.id, u.name, u.email, u.role,
              (SELECT COUNT(*) FROM user_customers uc WHERE uc.user_id = u.id) AS customers_count
         FROM users u
        ORDER BY u.id DESC`
    );
    res.json(rows);
  },

  async create(req, res) {
    const { name, email, password, role } = req.body || {};
    if (!name || !email || !password || !role) {
      return res.status(400).json({ error: 'name, email, password, role are required' });
    }
    if (!['super_admin','pm_admin','pm_user','finance'].includes(role)) {
      return res.status(400).json({ error: 'invalid role' });
    }
    const hash = await argon2.hash(password, { type: argon2.argon2id });
    try {
      const [r] = await pool.query(
        'INSERT INTO users (name, email, password_hash, role) VALUES (?,?,?,?)',
        [name, email, hash, role]
      );
      res.json({ id: r.insertId, ok: true });
    } catch (e) {
      if (e.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'email already exists' });
      throw e;
    }
  },

  async getAssignedCustomers(req, res) {
    const { id } = req.params;
    const [rows] = await pool.query(
      `SELECT uc.customer_id, c.name
         FROM user_customers uc
         JOIN customers c ON c.id = uc.customer_id
        WHERE uc.user_id = ?
        ORDER BY c.name`, [id]
    );
    res.json(rows);
  },

  async putAssignedCustomers(req, res) {
    const { id } = req.params;
    const { customer_ids } = req.body || {};
    if (!Array.isArray(customer_ids)) return res.status(400).json({ error: 'customer_ids array required' });

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      await conn.query('DELETE FROM user_customers WHERE user_id = ?', [id]);
      if (customer_ids.length) {
        const values = customer_ids.map(cid => [id, cid]);
        await conn.query('INSERT INTO user_customers (user_id, customer_id) VALUES ?', [values]);
      }
      await conn.commit();
    } catch (e) {
      await conn.rollback();
      throw e;
    } finally {
      conn.release();
    }
    res.json({ ok: true });
  },

  async updateRole(req, res) {
    const { id } = req.params;
    const { role } = req.body || {};
    if (!['super_admin','pm_admin','pm_user','finance'].includes(role)) {
      return res.status(400).json({ error: 'invalid role' });
    }
    await pool.query('UPDATE users SET role = ? WHERE id = ?', [role, id]);
    res.json({ ok: true });
  }
};
JS

# ---- Users Admin route: import the right auth export explicitly ----
cat > "$BACK/src/routes/usersAdmin.js" <<JS
import { Router } from 'express';
import * as Auth from '../middleware/auth.js';
import { UsersAdmin } from '../controllers/usersAdminController.js';

const authMw = ${AUTH_EXPORT === "default"
  ? "(Auth && Auth.default) || ((req,res,next)=>next())"
  : `(Auth && Auth.${AUTH_EXPORT}) || ((req,res,next)=>next())`};

const r = Router();
r.use(authMw, UsersAdmin.requireAdmin);

r.get('/', UsersAdmin.list);
r.post('/', UsersAdmin.create);
r.get('/:id/customers', UsersAdmin.getAssignedCustomers);
r.put('/:id/customers', UsersAdmin.putAssignedCustomers);
r.patch('/:id/role', UsersAdmin.updateRole);

export default r;
JS

# ---- Project Terms admin route: same auth import fix ----
cat > "$BACK/src/routes/projectTermsAdmin.js" <<JS
import { Router } from 'express';
import * as Auth from '../middleware/auth.js';
import { searchTerms, updateTermStatus } from '../controllers/projectTermsAdminController.js';

const authMw = ${AUTH_EXPORT === "default"
  ? "(Auth && Auth.default) || ((req,res,next)=>next())"
  : `(Auth && Auth.${AUTH_EXPORT}) || ((req,res,next)=>next())`};

const r = Router();
r.use(authMw);
r.get('/', searchTerms);
r.patch('/:id', updateTermStatus);
export default r;
JS

# ---- Ensure server.js imports/mounts the routes ----
SRV="$BACK/src/server.js"
grep -q "import usersAdminRoutes from './routes/usersAdmin.js';" "$SRV" || \
  sed -i "1 a import usersAdminRoutes from './routes/usersAdmin.js';" "$SRV"
grep -q "import projectTermsAdminRoutes from './routes/projectTermsAdmin.js';" "$SRV" || \
  sed -i "1 a import projectTermsAdminRoutes from './routes/projectTermsAdmin.js';" "$SRV"
grep -q "app.use('/api/users', usersAdminRoutes);" "$SRV" || \
  sed -i "/app.use(.*api\\/auth/a app.use('/api/users', usersAdminRoutes);" "$SRV"
grep -q "app.use('/api/project-terms', projectTermsAdminRoutes);" "$SRV" || \
  sed -i "/app.use(.*api\\/auth/a app.use('/api/project-terms', projectTermsAdminRoutes);" "$SRV"

# ---- Restart backend ----
pkill -f "node src/server.js" 2>/dev/null || true
cd "$BACK" && npm start >/dev/null 2>&1 &
echo "Patched and restarted backend."
