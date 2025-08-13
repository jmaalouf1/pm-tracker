set -euo pipefail

FRONT=~/projects/frontend
SRC="$FRONT/src"
BACK=~/projects/backend

mkdir -p "$SRC/pages" "$SRC/components"

############################################
# 1) Navbar: add "Payment Terms" menu item and fix toggler icon
############################################
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
    return nav('/')
  }
  return (
    <>
      <nav className="navbar navbar-expand-lg navbar-dark bg-primary">
        <div className="container-fluid">
          <Link className="navbar-brand" to="/">PM Tracker</Link>
          {/* Use clean text toggler to avoid the "?" icon */}
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
            </ul>
            <form className="d-flex ms-auto" onSubmit={onSearch}>
              <input className="form-control" placeholder="Jump: terms 12 / payment terms / customers" value={q} onChange={e=>setQ(e.target.value)} />
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
# 2) Project New: add Payment Terms editor inside the create form
#    (frontend creates project, then immediately saves terms)
############################################
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
    // 1) Create project
    const { data: created } = await api.post('/projects', form)
    const id = created.id || created.insertId || created.project_id || created?.data?.id
    if (!id) { alert('Project created but no ID returned.'); return }
    // 2) Save terms immediately (user perceives it as single creation flow)
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
          <div className="col-md-4"><label className="form-label">Status</label>{dd('status_id', opts.statuses.filter(s=>s.type==='project_status'))}</div>
          <div className="col-md-4"><label className="form-label">PO Status</label>{dd('po_status_id', opts.statuses.filter(s=>s.type==='po_status'))}</div>
          <div className="col-md-4"><label className="form-label">Invoice Status</label>{dd('invoice_status_id', opts.statuses.filter(s=>s.type==='invoice_status'))}</div>
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

############################################
# 3) New admin/search page for Payment Terms
############################################
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
      // Lightweight projects list pulled from /projects for now
      const proj = await api.get('/projects', { params: { search: '' } })
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
                {opts.customers.map(c=> <option key={c.id} value={c.id}>{c.name}</option>)}
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

############################################
# 4) Route the new Payment Terms page
############################################
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
        </Route>
      </Routes>
    </BrowserRouter>
  </AuthProvider>
)
JSX

############################################
# 5) Backend: add search + status update endpoints for terms
#    (no change to create flow; we already save terms via PUT after project create)
############################################
# Controller additions
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
  const { status_id } = req.body || {};
  await pool.query('UPDATE project_terms SET status_id = ?, updated_at = NOW() WHERE id = ?', [status_id || null, id]);
  res.json({ ok: true });
}
JS

# Route mounting
cat > "$BACK/src/routes/projectTermsAdmin.js" <<'JS'
import { Router } from 'express';
import { searchTerms, updateTermStatus } from '../controllers/projectTermsAdminController.js';
import { authMiddleware } from '../middleware/auth.js';

const r = Router();
r.use(authMiddleware);
r.get('/', searchTerms);
r.patch('/:id', updateTermStatus);
export default r;
JS

# Wire routes in server.js if not present
if ! grep -q "project-terms" "$BACK/src/server.js"; then
  sed -i "1 a import projectTermsAdminRoutes from './routes/projectTermsAdmin.js';" "$BACK/src/server.js"
  sed -i "/app.use(.*api\\/auth/a app.use('/api/project-terms', projectTermsAdminRoutes);" "$BACK/src/server.js" || true
fi

############################################
# 6) Rebuild & restart
############################################
cd "$FRONT"
npm run build

pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

pkill -f "node src/server.js" 2>/dev/null || true
cd "$BACK"
nohup npm start >/dev/null 2>&1 &

echo "Done. • New Project includes Payment Terms • Navbar toggler fixed • Payment Terms admin at /project-terms"
