set -euo pipefail

ROOT=~/projects
FRONT="$ROOT/frontend"
SRC="$FRONT/src"
BACK="$ROOT/backend"

echo "==> Preparing folders"
mkdir -p "$SRC/components" "$SRC/pages" "$SRC/context" "$SRC/services"
mkdir -p "$BACK/src/utils" "$BACK/src/middleware" "$BACK/src/controllers" "$BACK/src/routes" "$BACK/db/migrations"

############################################
# 1) Backend utilities: pagination & PM auth
############################################
echo "==> Writing backend utils and middleware"

cat > "$BACK/src/utils/query.js" <<'JS'
export function pageParams(req, fallbackSize = 20, maxSize = 100) {
  const page = Math.max(1, parseInt(req.query.page || '1', 10));
  const pageSize = Math.min(maxSize, Math.max(1, parseInt(req.query.pageSize || fallbackSize, 10)));
  const offset = (page - 1) * pageSize;
  return { page, pageSize, offset };
}
export function like(s) {
  if (!s) return '%';
  return `%${String(s).trim().replace(/[%_]/g, m => '\\' + m)}%`;
}
JS

cat > "$BACK/src/middleware/pmAuth.js" <<'JS'
import { pool } from '../db.js';

export async function canAccessCustomer(req, res, next) {
  try {
    const user = req.user;
    if (!user) return res.status(401).json({ error: 'unauthorized' });
    if (['super_admin','pm_admin','finance'].includes(user.role)) return next();

    if (user.role === 'pm_user') {
      let customerId = req.body?.customer_id;
      if (!customerId && req.params?.projectId) {
        const [[row]] = await pool.query('SELECT customer_id FROM projects WHERE id = ?', [req.params.projectId]);
        customerId = row?.customer_id;
      }
      if (!customerId) return res.status(400).json({ error: 'customer_id required' });
      const [[allowed]] = await pool.query(
        'SELECT 1 FROM user_customers WHERE user_id = ? AND customer_id = ?',
        [user.id, customerId]
      );
      if (!allowed) return res.status(403).json({ error: 'forbidden: customer not assigned to PM' });
    }
    next();
  } catch (e) { next(e); }
}
JS

############################################
# 2) Backend: Users Admin API
############################################
echo "==> Writing Users admin controller and routes"

cat > "$BACK/src/controllers/usersAdminController.js" <<'JS'
import { pool } from '../db.js';
import argon2 from 'argon2';

function requireAdmin(req, res, next) {
  const role = req.user?.role;
  if (role === 'super_admin' || role === 'pm_admin') return next();
  return res.status(403).json({ error: 'forbidden' });
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

cat > "$BACK/src/routes/usersAdmin.js" <<'JS'
import { Router } from 'express';
import * as Auth from '../middleware/auth.js';
import { UsersAdmin } from '../controllers/usersAdminController.js';

const authMw =
  (Auth && (Auth.authMiddleware || Auth.default || Auth.requireAuth || Auth.verifyToken))
  || ((req, res, next) => next()); // fallback if export name differs

const r = Router();
r.use(authMw, UsersAdmin.requireAdmin);

r.get('/', UsersAdmin.list);
r.post('/', UsersAdmin.create);
r.get('/:id/customers', UsersAdmin.getAssignedCustomers);
r.put('/:id/customers', UsersAdmin.putAssignedCustomers);
r.patch('/:id/role', UsersAdmin.updateRole);

export default r;
JS

############################################
# 3) Backend: Payment Terms admin search + status update
############################################
echo "==> Writing project terms admin controller and routes"

cat > "$BACK/src/controllers/projectTermsAdminController.js" <<'JS'
import { pool } from '../db.js';

export async function searchTerms(req, res) {
  const { project_id, customer_id, status_id, q } = req.query || {};
  const where = ['1=1'];
  const args = [];
  if (project_id) { where.push('t.project_id = ?'); args.push(project_id); }
  if (customer_id) { where.push('p.customer_id = ?'); args.push(customer_id); }
  if (status_id) { where.push('t.status_id = ?'); args.push(status_id); }
  if (q && q.trim()) { where.push('t.description LIKE ?'); args.push(`%${q.trim()}%`); }

  // PM restriction
  if (req.user?.role === 'pm_user') {
    where.push('p.customer_id IN (SELECT customer_id FROM user_customers WHERE user_id = ?)');
    args.push(req.user.id);
  }

  const [rows] = await pool.query(
    `SELECT t.*, p.name AS project_name, c.name AS customer_name
       FROM project_terms t
       JOIN projects p ON p.id = t.project_id
       LEFT JOIN customers c ON c.id = p.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY t.project_id, t.seq, t.id`,
    args
  );
  res.json(rows);
}

export async function updateTermStatus(req, res) {
  const { id } = req.params;
  // Check PM access by resolving customer
  const [[row]] = await pool.query(
    `SELECT p.customer_id FROM project_terms t JOIN projects p ON p.id = t.project_id WHERE t.id = ?`,
    [id]
  );
  if (!row) return res.status(404).json({ error: 'not found' });
  if (req.user?.role === 'pm_user') {
    const [[allowed]] = await pool.query(
      'SELECT 1 FROM user_customers WHERE user_id = ? AND customer_id = ?',
      [req.user.id, row.customer_id]
    );
    if (!allowed) return res.status(403).json({ error: 'forbidden' });
  }
  const { status_id } = req.body || {};
  await pool.query('UPDATE project_terms SET status_id = ?, updated_at = NOW() WHERE id = ?', [status_id || null, id]);
  res.json({ ok: true });
}
JS

cat > "$BACK/src/routes/projectTermsAdmin.js" <<'JS'
import { Router } from 'express';
import * as Auth from '../middleware/auth.js';
import { searchTerms, updateTermStatus } from '../controllers/projectTermsAdminController.js';
const authMw =
  (Auth && (Auth.authMiddleware || Auth.default || Auth.requireAuth || Auth.verifyToken))
  || ((req, res, next) => next());
const r = Router();
r.use(authMw);
r.get('/', searchTerms);
r.patch('/:id', updateTermStatus);
export default r;
JS

############################################
# 4) Backend: Projects listing with pagination + search + PM restriction
############################################
echo "==> Patching projects list route (pagination & q)"

# If your project keeps routes in src/routes/projects.js, add/patch there.
# If it uses controllers, adjust accordingly. We'll create/replace a route handler safely.

if [ -f "$BACK/src/routes/projects.js" ]; then
  awk '1' "$BACK/src/routes/projects.js" > "$BACK/src/routes/projects.js.bak"
fi

cat > "$BACK/src/routes/projects.js" <<'JS'
import { Router } from 'express';
import * as Auth from '../middleware/auth.js';
import { pool } from '../db.js';
import { pageParams, like } from '../utils/query.js';

const authMw =
  (Auth && (Auth.authMiddleware || Auth.default || Auth.requireAuth || Auth.verifyToken))
  || ((req, res, next) => next());

const router = Router();
router.use(authMw);

// LIST with pagination + q + PM restriction
router.get('/', async (req, res) => {
  const q = req.query.q;
  const { page, pageSize, offset } = pageParams(req, 20);
  const args = [];
  let where = '1=1';

  if (q && q.trim()) {
    where += ' AND (p.name LIKE ? OR c.name LIKE ?)';
    const L = like(q);
    args.push(L, L);
  }

  if (req.user?.role === 'pm_user') {
    where += ' AND p.customer_id IN (SELECT customer_id FROM user_customers WHERE user_id = ?)';
    args.push(req.user.id);
  }

  const [[{ cnt }]] = await pool.query(
    `SELECT COUNT(*) cnt FROM projects p LEFT JOIN customers c ON c.id = p.customer_id WHERE ${where}`,
    args
  );

  const [rows] = await pool.query(
    `SELECT p.*, c.name AS customer, s.name AS segment, st.name AS status
       FROM projects p
       LEFT JOIN customers c ON c.id = p.customer_id
       LEFT JOIN segments s ON s.id = p.segment_id
       LEFT JOIN statuses st ON st.id = p.status_id
      WHERE ${where}
      ORDER BY p.id DESC
      LIMIT ? OFFSET ?`,
    [...args, pageSize, offset]
  );
  res.json({ data: rows, page, pageSize, total: cnt });
});

export default router;
JS

############################################
# 5) Backend: wire new routers in server.js
############################################
echo "==> Wiring routes in server.js (users & project-terms admin)"
if ! grep -q "routes/usersAdmin.js" "$BACK/src/server.js"; then
  sed -i "1 a import usersAdminRoutes from './routes/usersAdmin.js';" "$BACK/src/server.js"
fi
if ! grep -q "routes/projectTermsAdmin.js" "$BACK/src/server.js"; then
  sed -i "1 a import projectTermsAdminRoutes from './routes/projectTermsAdmin.js';" "$BACK/src/server.js"
fi
if ! grep -q "app.use('/api/users'" "$BACK/src/server.js"; then
  sed -i "/app.use(.*api\\/auth/a app.use('/api/users', usersAdminRoutes);" "$BACK/src/server.js" || true
fi
if ! grep -q "app.use('/api/project-terms'" "$BACK/src/server.js"; then
  sed -i "/app.use(.*api\\/auth/a app.use('/api/project-terms', projectTermsAdminRoutes);" "$BACK/src/server.js" || true
fi

############################################
# 6) Frontend: Bootstrap shell + global CSS
############################################
echo "==> Writing frontend shell and styles"
cat > "$FRONT/index.html" <<'HTML'
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PM Tracker</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  </head>
  <body class="bg-light">
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
HTML

cat > "$SRC/app.css" <<'CSS'
.table thead th { position: sticky; top: 0; background: #fff; z-index: 1; }
.navbar-brand { font-weight: 800; letter-spacing:.2px; }
.form-label { font-weight: 600; }
.container-narrow { max-width: 720px; }
CSS

############################################
# 7) Frontend: Layout (with Payment Terms + Users link)
############################################
echo "==> Writing Layout.jsx"
cat > "$SRC/components/Layout.jsx" <<'JSX'
import React, { useState } from 'react'
import { Link, Outlet, useNavigate } from 'react-router-dom'
import '../app.css'

export default function Layout() {
  const nav = useNavigate()
  const [q, setQ] = useState('')
  function onSearch(e) {
    e.preventDefault()
    const s = q.trim().toLowerCase()
    if (!s) return
    if (s.includes('new project')) return nav('/projects/new')
    if (s.startsWith('terms')) { const id = s.replace(/\D+/g, ''); if (id) return nav(`/projects/${id}/terms`) }
    if (s.includes('customers')) return nav('/customers')
    if (s.includes('config')) return nav('/config')
    if (s.includes('payment terms') || s.includes('terms admin')) return nav('/project-terms')
    if (s.includes('users')) return nav('/users')
    return nav('/')
  }
  return (
    <>
      <nav className="navbar navbar-expand-lg navbar-dark bg-primary">
        <div className="container-fluid">
          <Link className="navbar-brand" to="/">PM Tracker</Link>
          <button className="navbar-toggler text-white border-0" type="button" data-bs-toggle="collapse" data-bs-target="#nav">Menu</button>
          <div id="nav" className="collapse navbar-collapse">
            <ul className="navbar-nav me-3">
              <li className="nav-item dropdown">
                <span className="nav-link dropdown-toggle" role="button" data-bs-toggle="dropdown">Projects</span>
                <ul className="dropdown-menu">
                  <li><Link className="dropdown-item" to="/">View Projects</Link></li>
                  <li><Link className="dropdown-item" to="/projects/new">New Project</Link></li>
                  <li><Link className="dropdown-item" to="/project-terms">Payment Terms</Link></li>
                </ul>
              </li>
              <li className="nav-item"><Link className="nav-link" to="/customers">Customers</Link></li>
              <li className="nav-item"><Link className="nav-link" to="/config">Config</Link></li>
              <li className="nav-item"><Link className="nav-link" to="/users">Users</Link></li>
            </ul>
            <form className="d-flex ms-auto" onSubmit={onSearch}>
              <input className="form-control" placeholder="Jump: terms 12 / payment terms / users" value={q} onChange={e=>setQ(e.target.value)} />
            </form>
          </div>
        </div>
      </nav>
      <main className="container py-4">
        <Outlet />
      </main>
    </>
  )
}
JSX

############################################
# 8) Frontend: Pages (Login, Projects list with instant search+pagination, New Project with terms, Terms view, Terms admin, Customers, Config, Users)
############################################
echo "==> Writing pages"

# Login
cat > "$SRC/pages/Login.jsx" <<'JSX'
import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function Login() {
  const [email, setEmail] = useState('admin@example.com')
  const [password, setPassword] = useState('Admin@12345')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const { login } = useAuth()
  const nav = useNavigate()
  async function submit(e) {
    e.preventDefault(); setBusy(true); setError('')
    try { await login(email, password); nav('/') }
    catch (e) { setError(e.message || 'Login failed') }
    finally { setBusy(false) }
  }
  return (
    <div className="d-flex justify-content-center align-items-center" style={{minHeight:'70vh'}}>
      <div className="card shadow-sm container-narrow w-100">
        <div className="card-body">
          <h4 className="card-title mb-3">Sign in</h4>
          <form onSubmit={submit}>
            <div className="mb-3">
              <label className="form-label">Email</label>
              <input className="form-control" type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
            </div>
            <div className="mb-3">
              <label className="form-label">Password</label>
              <input className="form-control" type="password" value={password} onChange={e=>setPassword(e.target.value)} required />
            </div>
            {error ? <div className="text-danger small mb-2">{error}</div> : null}
            <button className="btn btn-primary" disabled={busy}>{busy ? 'Signing in…' : 'Login'}</button>
          </form>
        </div>
      </div>
    </div>
  )
}
JSX

# ProjectsList with instant search + server pagination
cat > "$SRC/pages/ProjectsList.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { Link } from 'react-router-dom'

export default function ProjectsList() {
  const [rows, setRows] = useState([])
  const [q, setQ] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [total, setTotal] = useState(0)
  const [busy, setBusy] = useState(false)

  async function load(p = page) {
    setBusy(true)
    const { data } = await api.get('/projects', { params: { q, page: p, pageSize } })
    setRows(data.data)
    setTotal(data.total)
    setPage(data.page)
    setBusy(false)
  }
  useEffect(() => { load(1) }, [])
  useEffect(() => { const id = setTimeout(() => load(1), 250); return () => clearTimeout(id) }, [q, pageSize])

  const pages = Math.max(1, Math.ceil(total / pageSize))

  return (
    <>
      <div className="d-flex gap-2 mb-3">
        <input className="form-control" placeholder="Search projects…" value={q} onChange={e=>setQ(e.target.value)} />
        <Link className="btn btn-primary" to="/projects/new">New Project</Link>
      </div>
      <div className="table-responsive shadow-sm">
        <table className="table table-sm table-striped align-middle">
          <thead><tr>
            <th>ID</th><th>Name</th><th>Customer</th><th>Segment</th><th>Status</th>
            <th className="text-end">Remaining %</th><th className="text-end">Backlog</th><th>Actions</th>
          </tr></thead>
          <tbody>
            {rows.map(r=>(
              <tr key={r.id}>
                <td>{r.id}</td>
                <td>{r.name}</td>
                <td>{r.customer||''}</td>
                <td>{r.segment||''}</td>
                <td>{r.status||''}</td>
                <td className="text-end">{Number(r.remaining_percent||0).toFixed(2)}%</td>
                <td className="text-end">{Number(r.backlog_amount||0).toLocaleString(undefined,{minimumFractionDigits:2,maximumFractionDigits:2})}</td>
                <td><Link to={`/projects/${r.id}/terms`} className="btn btn-sm btn-outline-primary">Manage Terms</Link></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="d-flex justify-content-between align-items-center mt-2">
        <div className="d-flex align-items-center gap-2">
          <span>Rows:</span>
          <select className="form-select form-select-sm" style={{width:'auto'}} value={pageSize} onChange={e=>setPageSize(Number(e.target.value))}>
            {[10,20,50,100].map(n => <option key={n} value={n}>{n}</option>)}
          </select>
          <span className="text-muted">Total: {total}</span>
        </div>
        <div className="btn-group">
          <button className="btn btn-sm btn-outline-secondary" disabled={page<=1} onClick={()=>{setPage(1);load(1)}}>«</button>
          <button className="btn btn-sm btn-outline-secondary" disabled={page<=1} onClick={()=>{setPage(page-1);load(page-1)}}>‹</button>
          <span className="btn btn-sm btn-light disabled">{page} / {Math.max(1, Math.ceil(total/pageSize))}</span>
          <button className="btn btn-sm btn-outline-secondary" disabled={page>=pages} onClick={()=>{setPage(page+1);load(page+1)}}>›</button>
          <button className="btn btn-sm btn-outline-secondary" disabled={page>=pages} onClick={()=>{setPage(pages);load(pages)}}>»</button>
        </div>
      </div>
    </>
  )
}
JSX

# ProjectNew with Payment Terms in the creation flow
cat > "$SRC/pages/ProjectNew.jsx" <<'JSX'
import React, { useEffect, useMemo, useState } from 'react'
import api from '../services/api'
function clamp(n){ n=Number(n||0); if(isNaN(n)) n=0; return Math.max(0, Math.min(100, n)) }

export default function ProjectNew() {
  const [form, setForm] = useState({ name: '', contract_value: 0 })
  const [opts, setOpts] = useState({ customers: [], segments: [], service_lines: [], partners: [], statuses: [] })
  const [terms, setTerms] = useState([{ percentage: 100, description: 'Milestone 1', status_id: null }])
  const total = useMemo(()=> terms.reduce((a,b)=>a+clamp(b.percentage),0), [terms])
  const termsValid = Math.abs(total-100)<=0.01 && terms.every(t=>String(t.description||'').trim().length)

  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,segments,service_lines,partners,statuses' } })
      setOpts(data)
    }
    load()
  }, [])

  function change(k, v) { setForm(s => ({ ...s, [k]: v })) }
  function addRow(){ setTerms(ts=>[...ts,{ percentage:0, description:'', status_id:null }]) }
  function upd(i,k,v){ setTerms(ts=>ts.map((t,idx)=> idx===i? {...t,[k]:k==='percentage'?clamp(v):v }:t)) }
  function del(i){ setTerms(ts=> ts.filter((_,idx)=> idx!==i)) }

  const dd = (name, list) => (
    <select className="form-select" value={form[name] || ''} onChange={e=>change(name, e.target.value || null)}>
      <option value="">--</option>
      {list.map(o => <option key={o.id} value={o.id}>{o.name}</option>)}
    </select>
  )

  async function submit(e) {
    e.preventDefault()
    if (!termsValid) { alert('Payment terms must total 100% and each row needs a description.'); return }
    const { data: created } = await api.post('/projects', form)
    const id = created.id || created.insertId || created.project_id || created?.data?.id
    if (!id) { alert('Project created but no ID returned.'); return }
    await api.put(`/projects/${id}/terms`, { terms: terms.map((t,idx)=> ({ ...t, seq: idx+1, percentage: clamp(t.percentage) })) })
    alert('Project created with payment terms.')
    window.location.href = `/projects/${id}/terms`
  }

  return (
    <form onSubmit={submit} className="card shadow-sm">
      <div className="card-body">
        <h4 className="mb-3">New Project</h4>
        <div className="row g-3">
          <div className="col-md-8">
            <label className="form-label">Name</label>
            <input className="form-control" value={form.name} onChange={e=>change('name', e.target.value)} required />
          </div>
          <div className="col-md-4">
            <label className="form-label">Contract Value</label>
            <input className="form-control" type="number" step="0.01" value={form.contract_value || 0} onChange={e=>change('contract_value', e.target.value)} />
          </div>
          <div className="col-md-6"><label className="form-label">Customer</label>{dd('customer_id', opts.customers)}</div>
          <div className="col-md-6"><label className="form-label">Segment</label>{dd('segment_id', opts.segments)}</div>
          <div className="col-md-6"><label className="form-label">Service Line</label>{dd('service_line_id', opts.service_lines)}</div>
          <div className="col-md-6"><label className="form-label">Partner</label>{dd('partner_id', opts.partners)}</div>
          <div className="col-md-4"><label className="form-label">Status</label>{dd('status_id', (opts.statuses||[]).filter(s=>s.type==='project_status'))}</div>
          <div className="col-md-4"><label className="form-label">PO Status</label>{dd('po_status_id', (opts.statuses||[]).filter(s=>s.type==='po_status'))}</div>
          <div className="col-md-4"><label className="form-label">Invoice Status</label>{dd('invoice_status_id', (opts.statuses||[]).filter(s=>s.type==='invoice_status'))}</div>
        </div>

        <hr className="my-4" />
        <h5 className="mb-3">Payment Terms (must total 100%)</h5>
        <div className="table-responsive">
          <table className="table table-sm align-middle">
            <thead><tr><th>#</th><th className="text-end">%</th><th>Description</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {terms.map((t,i)=>(
                <tr key={i}>
                  <td>{i+1}</td>
                  <td style={{width:130}} className="text-end">
                    <input type="number" min="0" max="100" step="0.01" className="form-control form-control-sm text-end"
                           value={t.percentage} onChange={e=>upd(i,'percentage',e.target.value)} />
                  </td>
                  <td><input className="form-control form-control-sm" value={t.description} onChange={e=>upd(i,'description',e.target.value)} placeholder="e.g. UAT sign-off" /></td>
                  <td style={{width:220}}>
                    <select className="form-select form-select-sm" value={t.status_id||''} onChange={e=>upd(i,'status_id', e.target.value?Number(e.target.value):null)}>
                      <option value="">--</option>
                      {(opts.statuses||[]).filter(s=>s.type==='term_status').map(s=><option key={s.id} value={s.id}>{s.name}</option>)}
                    </select>
                  </td>
                  <td style={{width:90}}><button type="button" className="btn btn-sm btn-outline-danger" onClick={()=>del(i)}>Remove</button></td>
                </tr>
              ))}
            </tbody>
            <tfoot><tr><th>Total</th><th className="text-end">{total.toFixed(2)}%</th><th colSpan="3"></th></tr></tfoot>
          </table>
        </div>
        <div className="d-flex gap-2">
          <button type="button" className="btn btn-outline-secondary" onClick={addRow}>Add Row</button>
          <button className="btn btn-primary" disabled={!termsValid}>Create Project with Terms</button>
        </div>
      </div>
    </form>
  )
}
JSX

# ProjectTerms (view/edit)
cat > "$SRC/pages/ProjectTerms.jsx" <<'JSX'
import React, { useEffect, useMemo, useState } from 'react'
import api from '../services/api'
import { useParams } from 'react-router-dom'
function clamp(n){ n=Number(n||0); if(isNaN(n)) n=0; return Math.max(0, Math.min(100, n)) }
export default function ProjectTerms(){
  const { id } = useParams()
  const [terms, setTerms] = useState([])
  const [statuses, setStatuses] = useState([])
  const [project, setProject] = useState(null)
  const [msg, setMsg] = useState('')
  const total = useMemo(()=> terms.reduce((a,b)=>a+clamp(b.percentage),0), [terms])
  const valid = Math.abs(total-100)<=0.01 && terms.every(t=>String(t.description||'').trim().length)
  async function load(){
    const p = await api.get('/projects/'+id); setProject(p.data)
    const list = await api.get('/projects/'+id+'/terms'); setTerms(list.data.length?list.data:[{percentage:100,description:'Milestone 1',status_id:null}])
    const opt = await api.get('/config/options',{params:{types:'statuses'}}); setStatuses(opt.data.statuses.filter(s=>s.type==='term_status'))
  }
  useEffect(()=>{ load() },[id])
  function addRow(){ setTerms(ts=>[...ts,{percentage:0,description:'',status_id:null}]) }
  function upd(i,k,v){ setTerms(ts=>ts.map((t,idx)=>idx===i?{...t,[k]:k==='percentage'?clamp(v):v}:t)) }
  function del(i){ setTerms(ts=>ts.filter((_,idx)=>idx!==i)) }
  async function save(){ setMsg(''); if(!valid){ setMsg('Descriptions required and total must be 100%. Current: '+total.toFixed(2)+'%'); return }
    await api.put('/projects/'+id+'/terms',{terms:terms.map((t,idx)=>({...t,seq:idx+1,percentage:clamp(t.percentage)}))})
    setMsg('Saved'); await load()
  }
  return (
    <div className="card shadow-sm">
      <div className="card-body">
        <h4 className="mb-3">Project Terms {project?('— '+project.name):''}</h4>
        <div className="table-responsive">
          <table className="table table-sm align-middle">
            <thead><tr><th>#</th><th className="text-end">%</th><th>Description</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {terms.map((t,i)=>(
                <tr key={i}>
                  <td>{i+1}</td>
                  <td className="text-end" style={{width:120}}>
                    <input type="number" min="0" max="100" step="0.01" className="form-control form-control-sm text-end"
                           value={t.percentage} onChange={e=>upd(i,'percentage',e.target.value)} />
                  </td>
                  <td><input className="form-control form-control-sm" value={t.description} onChange={e=>upd(i,'description',e.target.value)} placeholder="e.g. UAT sign-off" /></td>
                  <td style={{width:220}}>
                    <select className="form-select form-select-sm" value={t.status_id||''} onChange={e=>upd(i,'status_id', e.target.value?Number(e.target.value):null)}>
                      <option value="">--</option>
                      {statuses.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}
                    </select>
                  </td>
                  <td style={{width:90}}><button className="btn btn-sm btn-outline-danger" onClick={()=>del(i)}>Remove</button></td>
                </tr>
              ))}
            </tbody>
            <tfoot><tr><th>Total</th><th className="text-end">{total.toFixed(2)}%</th><th colSpan="3"></th></tr></tfoot>
          </table>
        </div>
        <div className="d-flex gap-2">
          <button className="btn btn-outline-secondary" onClick={addRow}>Add Row</button>
          <button className="btn btn-primary" onClick={save} disabled={!valid}>Save Terms</button>
          {msg && <div className="ms-2">{msg}</div>}
        </div>
      </div>
    </div>
  )
}
JSX

# PaymentTerms admin page
cat > "$SRC/pages/PaymentTerms.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'

export default function PaymentTerms() {
  const [filters, setFilters] = useState({ project_id:'', customer_id:'', status_id:'', q:'' })
  const [opts, setOpts] = useState({ projects: [], customers: [], statuses: [] })
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,statuses' } })
      setOpts(o => ({ ...o, customers: data.customers || [], statuses: (data.statuses || []).filter(s=>s.type==='term_status') }))
      const proj = await api.get('/projects', { params: { q: '', page: 1, pageSize: 1000 } })
      setOpts(o => ({ ...o, projects: proj.data.data || [] }))
    }
    load()
  }, [])

  async function search() {
    setLoading(true)
    const { data } = await api.get('/project-terms', { params: filters })
    setRows(data)
    setLoading(false)
  }

  async function updateStatus(id, status_id) {
    await api.patch(`/project-terms/${id}`, { status_id: status_id || null })
    await search()
  }

  return (
    <div>
      <h2 className="mb-3">Payment Terms</h2>
      <div className="card shadow-sm mb-3">
        <div className="card-body">
          <div className="row g-2 align-items-end">
            <div className="col-md-3">
              <label className="form-label">Project</label>
              <select className="form-select" value={filters.project_id} onChange={e=>setFilters(f=>({...f,project_id:e.target.value}))}>
                <option value="">Any</option>
                {opts.projects.map(p=> <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
            </div>
            <div className="col-md-3">
              <label className="form-label">Customer</label>
              <select className="form-select" value={filters.customer_id} onChange={e=>setFilters(f=>({...f,customer_id:e.target.value}))}>
                <option value="">Any</option>
                {opts.customers.map(c=> <option key={c.id} value={c.id}>{c.name} {c.country?`— ${c.country}`:''}</option>)}
              </select>
            </div>
            <div className="col-md-3">
              <label className="form-label">Term Status</label>
              <select className="form-select" value={filters.status_id} onChange={e=>setFilters(f=>({...f,status_id:e.target.value}))}>
                <option value="">Any</option>
                {opts.statuses.map(s=> <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>
            <div className="col-md-3">
              <label className="form-label">Text</label>
              <input className="form-control" placeholder="Description contains…" value={filters.q} onChange={e=>setFilters(f=>({...f,q:e.target.value}))} />
            </div>
          </div>
          <div className="mt-3">
            <button className="btn btn-primary" onClick={search} disabled={loading}>{loading?'Searching…':'Search'}</button>
          </div>
        </div>
      </div>

      <div className="table-responsive shadow-sm">
        <table className="table table-sm table-striped align-middle">
          <thead><tr>
            <th>ID</th><th>Project</th><th>Customer</th><th className="text-end">%</th><th>Description</th><th>Status</th><th>Updated</th>
          </tr></thead>
          <tbody>
            {rows.map(r=>(
              <tr key={r.id}>
                <td>{r.id}</td>
                <td>{r.project_name}</td>
                <td>{r.customer_name||''}</td>
                <td className="text-end">{Number(r.percentage||0).toFixed(2)}</td>
                <td>{r.description}</td>
                <td style={{width:240}}>
                  <select className="form-select form-select-sm" value={r.status_id || ''} onChange={e=>updateStatus(r.id, e.target.value?Number(e.target.value):null)}>
                    <option value="">--</option>
                    {(opts.statuses||[]).map(s=> <option key={s.id} value={s.id}>{s.name}</option>)}
                  </select>
                </td>
                <td>{r.updated_at ? new Date(r.updated_at).toLocaleString() : ''}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
JSX

# Customers page (kept as in previous step with clean layout)
cat > "$SRC/pages/Customers.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'

const TYPES = [
  { value: 'bank', label: 'Bank' },
  { value: 'fintech', label: 'Fintech' },
  { value: 'digital_bank', label: 'Digital Bank' },
  { value: 'government', label: 'Government Entity' },
  { value: 'nfi', label: 'NFI' },
  { value: 'other', label: 'Other' },
]

export default function Customers() {
  const [rows, setRows] = useState([])
  const [q, setQ] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [total, setTotal] = useState(0)

  async function load(p=page){
    const { data } = await api.get('/customers', { params: { q, page: p, pageSize } })
    setRows(data.data || data) // depending on your current endpoint shape
    setTotal(data.total || data.length || 0)
    setPage(data.page || p)
  }
  useEffect(()=>{ load(1) },[])
  useEffect(()=>{ const id=setTimeout(()=>load(1),250); return ()=>clearTimeout(id) },[q,pageSize])

  const pages = Math.max(1, Math.ceil((total||0)/pageSize))

  return (
    <div>
      <h2 className="mb-3">Customers</h2>
      <div className="d-flex gap-2 mb-3">
        <input className="form-control" placeholder="Search by name/CR/VAT…" value={q} onChange={e=>setQ(e.target.value)} />
      </div>

      <div className="table-responsive shadow-sm">
        <table className="table table-sm table-striped align-middle">
          <thead><tr><th>Name</th><th>Country</th><th>Type</th><th>CR</th><th>VAT</th><th>#Contacts</th></tr></thead>
          <tbody>
            {rows.map(r => (
              <tr key={r.id}>
                <td>{r.name}</td>
                <td>{r.country ? <span>{r.country} <span className="text-primary small">•</span></span> : ''}</td>
                <td>{r.type || ''}</td>
                <td>{r.commercial_registration || ''}</td>
                <td>{r.vat_number || ''}</td>
                <td>{r.contacts_count || 0}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="d-flex justify-content-between align-items-center mt-2">
        <div className="d-flex align-items-center gap-2">
          <span>Rows:</span>
          <select className="form-select form-select-sm" style={{width:'auto'}} value={pageSize} onChange={e=>setPageSize(Number(e.target.value))}>
            {[10,20,50,100].map(n => <option key={n} value={n}>{n}</option>)}
          </select>
          <span className="text-muted">Total: {total}</span>
        </div>
        <div className="btn-group">
          <button className="btn btn-sm btn-outline-secondary" disabled={page<=1} onClick={()=>{setPage(1);load(1)}}>«</button>
          <button className="btn btn-sm btn-outline-secondary" disabled={page<=1} onClick={()=>{setPage(page-1);load(page-1)}}>‹</button>
          <span className="btn btn-sm btn-light disabled">{page} / {pages}</span>
          <button className="btn btn-sm btn-outline-secondary" disabled={page>=pages} onClick={()=>{setPage(page+1);load(page+1)}}>›</button>
          <button className="btn btn-sm btn-outline-secondary" disabled={page>=pages} onClick={()=>{setPage(pages);load(pages)}}>»</button>
        </div>
      </div>
    </div>
  )
}
JSX

# Config page (same as earlier clean editor)
cat > "$SRC/pages/Config.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'

function Editor({ title, type, rows, setRows }) {
  const [name, setName] = useState('')
  const [statusType, setStatusType] = useState('project_status')
  async function add() {
    if (type === 'statuses')
      await api.post('/config/options/'+type, { name, statusType })
    else
      await api.post('/config/options/'+type, { name })
    setName('')
    const { data } = await api.get('/config/options', { params: { types: type } })
    setRows(data[type])
  }
  async function save(r) {
    await api.put(`/config/options/${type}/${r.id}`, { name: r.name, is_active: r.is_active })
  }
  return (
    <div className="card shadow-sm mb-4">
      <div className="card-body">
        <h5 className="mb-3">{title}</h5>
        <div className="d-flex gap-2 mb-2">
          {type === 'statuses' ? (
            <select className="form-select w-auto" value={statusType} onChange={e=>setStatusType(e.target.value)}>
              <option value="project_status">Project Status</option>
              <option value="invoice_status">Invoice Status</option>
              <option value="po_status">PO Status</option>
              <option value="term_status">Term Status</option>
            </select>
          ) : null}
          <input className="form-control" placeholder="Name" value={name} onChange={e=>setName(e.target.value)} />
          <button className="btn btn-outline-secondary" onClick={add}>Add</button>
        </div>
        <div className="table-responsive">
          <table className="table table-sm">
            <thead><tr><th>Name</th><th>Active</th><th>Save</th></tr></thead>
            <tbody>
              {rows.map(r => (
                <tr key={r.id}>
                  <td><input className="form-control form-control-sm" value={r.name} onChange={e=>setRows(list=>list.map(x=>x.id===r.id?{...x,name:e.target.value}:x))} /></td>
                  <td><input type="checkbox" checked={!!r.is_active} onChange={e=>setRows(list=>list.map(x=>x.id===r.id?{...x,is_active:e.target.checked?1:0}:x))} /></td>
                  <td><button className="btn btn-sm btn-outline-primary" onClick={()=>save(r)}>Save</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

export default function Config() {
  const [data, setData] = useState({ segments: [], service_lines: [], partners: [], statuses: [] })
  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'segments,service_lines,partners,statuses,customers' } })
      setData(data)
    }
    load()
  }, [])
  return (
    <div>
      <h2 className="mb-3">Dropdowns & Statuses</h2>
      <Editor title="Segments" type="segments" rows={data.segments||[]} setRows={rows=>setData(s=>({...s, segments: rows}))} />
      <Editor title="Service Lines" type="service_lines" rows={data.service_lines||[]} setRows={rows=>setData(s=>({...s, service_lines: rows}))} />
      <Editor title="Partners" type="partners" rows={data.partners||[]} setRows={rows=>setData(s=>({...s, partners: rows}))} />
      <Editor title="Statuses" type="statuses" rows={data.statuses||[]} setRows={rows=>setData(s=>({...s, statuses: rows}))} />
    </div>
  )
}
JSX

# Users admin page
cat > "$SRC/pages/Users.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../context/AuthContext'

const ROLES = ['super_admin','pm_admin','pm_user','finance']

export default function Users(){
  const { user } = useAuth()
  const [rows, setRows] = useState([])
  const [customers, setCustomers] = useState([])
  const [busy, setBusy] = useState(false)
  const [form, setForm] = useState({ name:'', email:'', password:'', role:'pm_user' })
  const [assigning, setAssigning] = useState(null)
  const [selected, setSelected] = useState([])
  const isAdmin = user && (user.role === 'super_admin' || user.role === 'pm_admin')

  async function load(){
    setBusy(true)
    const u = await api.get('/users'); setRows(u.data)
    const c = await api.get('/config/options', { params: { types: 'customers' } })
    setCustomers(c.data.customers || [])
    setBusy(false)
  }
  useEffect(()=>{ load() },[])

  async function create(e){
    e.preventDefault()
    await api.post('/users', form)
    setForm({ name:'', email:'', password:'', role:'pm_user' })
    await load()
  }
  async function openAssign(u){
    setAssigning(u)
    const { data } = await api.get('/users/'+u.id+'/customers')
    setSelected(data.map(d=>d.customer_id))
  }
  function toggle(cid){ setSelected(s => s.includes(cid) ? s.filter(x=>x!==cid) : [...s, cid]) }
  async function saveAssign(){ await api.put('/users/'+assigning.id+'/customers', { customer_ids: selected }); setAssigning(null); setSelected([]); await load() }
  async function changeRole(u, role){ await api.patch('/users/'+u.id+'/role', { role }); await load() }

  if (!isAdmin) return <div className="alert alert-warning">You need admin permissions to manage users.</div>

  return (
    <div>
      <h2 className="mb-3">Users</h2>
      <div className="card shadow-sm mb-4">
        <div className="card-body">
          <h5 className="mb-3">Create User</h5>
          <form onSubmit={create} className="row g-3">
            <div className="col-md-3"><label className="form-label">Name</label><input className="form-control" value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} required /></div>
            <div className="col-md-3"><label className="form-label">Email</label><input className="form-control" type="email" value={form.email} onChange={e=>setForm(f=>({...f,email:e.target.value}))} required /></div>
            <div className="col-md-3"><label className="form-label">Password</label><input className="form-control" type="password" value={form.password} onChange={e=>setForm(f=>({...f,password:e.target.value}))} required /></div>
            <div className="col-md-2"><label className="form-label">Role</label>
              <select className="form-select" value={form.role} onChange={e=>setForm(f=>({...f,role:e.target.value}))}>{ROLES.map(r=> <option key={r} value={r}>{r}</option>)}</select>
            </div>
            <div className="col-md-1 d-flex align-items-end"><button className="btn btn-primary" disabled={busy}>Create</button></div>
          </form>
        </div>
      </div>

      <div className="table-responsive shadow-sm">
        <table className="table table-sm table-striped align-middle">
          <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Role</th><th>#Customers</th><th>Actions</th></tr></thead>
          <tbody>
            {rows.map(u=>(
              <tr key={u.id}>
                <td>{u.id}</td><td>{u.name}</td><td>{u.email}</td>
                <td style={{width:220}}>
                  <select className="form-select form-select-sm" value={u.role} onChange={e=>changeRole(u, e.target.value)}>
                    {ROLES.map(r=> <option key={r} value={r}>{r}</option>)}
                  </select>
                </td>
                <td>{u.customers_count}</td>
                <td><button className="btn btn-sm btn-outline-primary" onClick={()=>openAssign(u)}>Manage Customers</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {assigning && (
        <div className="card shadow-sm mt-3">
          <div className="card-body">
            <h5 className="mb-2">Assign Customers to {assigning.name}</h5>
            <div className="row g-2">
              {customers.map(c=>(
                <div key={c.id} className="col-md-3">
                  <label className="form-check">
                    <input type="checkbox" className="form-check-input" checked={selected.includes(c.id)} onChange={()=>toggle(c.id)} />
                    <span className="form-check-label">{c.name} {c.country ? <span className="text-primary small ms-1">{c.country}</span> : null}</span>
                  </label>
                </div>
              ))}
            </div>
            <div className="mt-3 d-flex gap-2">
              <button className="btn btn-primary" onClick={saveAssign}>Save</button>
              <button className="btn btn-outline-secondary" onClick={()=>{ setAssigning(null); setSelected([]); }}>Cancel</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
JSX

# main.jsx routes
cat > "$SRC/main.jsx" <<'JSX'
import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Layout from './components/Layout'
import Login from './pages/Login'
import ProjectsList from './pages/ProjectsList'
import ProjectNew from './pages/ProjectNew'
import ProjectTerms from './pages/ProjectTerms'
import PaymentTerms from './pages/PaymentTerms'
import Customers from './pages/Customers'
import Config from './pages/Config'
import Users from './pages/Users'
import './app.css'

function Protected({ children }) {
  const { user } = useAuth()
  return user ? children : <Navigate to="/login" replace />
}

createRoot(document.getElementById('root')).render(
  <AuthProvider>
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<Protected><Layout /></Protected>}>
          <Route index element={<ProjectsList />} />
          <Route path="projects/new" element={<ProjectNew />} />
          <Route path="projects/:id/terms" element={<ProjectTerms />} />
          <Route path="project-terms" element={<PaymentTerms />} />
          <Route path="customers" element={<Customers />} />
          <Route path="config" element={<Config />} />
          <Route path="users" element={<Users />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </AuthProvider>
)
JSX

############################################
# 9) Build frontend & restart servers
############################################
echo "==> Installing backend deps (argon2 if missing)"
cd "$BACK"
npm pkg get dependencies.argon2 >/dev/null 2>&1 || npm i argon2

echo "==> Restarting backend"
pkill -f "node src/server.js" 2>/dev/null || true
nohup npm start >/dev/null 2>&1 &

echo "==> Building frontend"
cd "$FRONT"
npm run build

echo "==> Restarting frontend static server"
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "==> DONE. Open your app and test:"
echo "  - / (Projects) with instant search + pagination"
echo "  - /projects/new (create project incl. payment terms)"
echo "  - /projects/:id/terms (edit terms)"
echo "  - /project-terms (search/update term status)"
echo "  - /users (admin only) to manage users & PM assignments"
