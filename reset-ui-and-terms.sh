set -euo pipefail

FRONT=~/projects/frontend
SRC="$FRONT/src"
BACK=~/projects/backend

mkdir -p "$SRC/components" "$SRC/pages" "$SRC/context" "$SRC/services"

# ---------- index.html with Bootstrap ----------
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

# ---------- global CSS tweaks ----------
cat > "$SRC/app.css" <<'CSS'
.table thead th { position: sticky; top: 0; background: #fff; z-index: 1; }
.navbar-brand { font-weight: 800; letter-spacing:.2px; }
.form-label { font-weight: 600; }
.container-narrow { max-width: 720px; }
CSS

# ---------- Top navbar layout ----------
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
    return nav('/')
  }
  return (
    <>
      <nav className="navbar navbar-expand-lg navbar-dark bg-primary">
        <div className="container-fluid">
          <Link className="navbar-brand" to="/">PM Tracker</Link>
          <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#nav">
            <span className="navbar-toggler-icon"></span>
          </button>
          <div id="nav" className="collapse navbar-collapse">
            <ul className="navbar-nav me-3">
              <li className="nav-item dropdown">
                <span className="nav-link dropdown-toggle" role="button" data-bs-toggle="dropdown">Projects</span>
                <ul className="dropdown-menu">
                  <li><Link className="dropdown-item" to="/">View Projects</Link></li>
                  <li><Link className="dropdown-item" to="/projects/new">New Project</Link></li>
                </ul>
              </li>
              <li className="nav-item"><Link className="nav-link" to="/customers">Customers</Link></li>
              <li className="nav-item"><Link className="nav-link" to="/config">Config</Link></li>
            </ul>
            <form className="d-flex ms-auto" onSubmit={onSearch}>
              <input className="form-control" placeholder="Jump: terms 12 / customers / config" value={q} onChange={e=>setQ(e.target.value)} />
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

# ---------- Login ----------
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

# ---------- Projects list (Manage Terms visible) ----------
cat > "$SRC/pages/ProjectsList.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { Link } from 'react-router-dom'

export default function ProjectsList() {
  const [rows, setRows] = useState([])
  const [q, setQ] = useState('')
  const [busy, setBusy] = useState(false)
  async function load(){ setBusy(true); const {data}=await api.get('/projects',{params:{search:q}}); setRows(data.data); setBusy(false) }
  useEffect(()=>{ load() },[])
  return (
    <>
      <div className="d-flex gap-2 mb-3">
        <input className="form-control" placeholder="Search projects…" value={q} onChange={e=>setQ(e.target.value)} />
        <button className="btn btn-outline-secondary" onClick={load} disabled={busy}>Search</button>
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
    </>
  )
}
JSX

# ---------- New Project (kept simple; adds contract value) ----------
cat > "$SRC/pages/ProjectNew.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'

export default function ProjectNew() {
  const [form, setForm] = useState({ name: '', contract_value: 0 })
  const [opts, setOpts] = useState({ customers: [], segments: [], service_lines: [], partners: [], statuses: [] })

  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,segments,service_lines,partners,statuses' } })
      setOpts(data)
    }
    load()
  }, [])

  function change(k, v) { setForm(s => ({ ...s, [k]: v })) }

  async function submit(e) {
    e.preventDefault()
    await api.post('/projects', form)
    alert('Project created')
    setForm({ name: '', contract_value: 0 })
  }

  const dd = (name, list) => (
    <select className="form-select" value={form[name] || ''} onChange={e=>change(name, e.target.value || null)}>
      <option value="">--</option>
      {list.map(o => <option key={o.id} value={o.id}>{o.name}</option>)}
    </select>
  )

  return (
    <form onSubmit={submit} className="card shadow-sm container-narrow w-100">
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
        <div className="mt-3">
          <button className="btn btn-primary">Create</button>
        </div>
      </div>
    </form>
  )
}
JSX

# ---------- Customers (Bootstrap grid) ----------
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
  const [showNew, setShowNew] = useState(false)
  const [form, setForm] = useState({ name: '', country: '', type: '', commercial_registration: '', vat_number: '', contacts: [] })
  const [contact, setContact] = useState({ role:'', name:'', email:'', phone:'' })

  async function load() {
    const { data } = await api.get('/customers', { params: q ? { q } : undefined })
    setRows(data)
  }
  useEffect(()=>{ load() }, [])

  function addContact() {
    if (!contact.name) return
    setForm(f => ({ ...f, contacts: [...(f.contacts||[]), contact] }))
    setContact({ role:'', name:'', email:'', phone:'' })
  }

  async function create(e) {
    e.preventDefault()
    await api.post('/customers', form)
    setShowNew(false)
    setForm({ name: '', country: '', type: '', commercial_registration: '', vat_number: '', contacts: [] })
    await load()
  }

  return (
    <div>
      <h2 className="mb-3">Customers</h2>
      <div className="d-flex gap-2 mb-3">
        <input className="form-control" placeholder="Search by name/CR/VAT…" value={q} onChange={e=>setQ(e.target.value)} />
        <button className="btn btn-outline-secondary" onClick={load}>Search</button>
        <button className="btn btn-primary" onClick={()=>setShowNew(s=>!s)}>{showNew?'Close':'New Customer'}</button>
      </div>

      {showNew && (
        <div className="card shadow-sm mb-4">
          <div className="card-body">
            <h5 className="card-title mb-3">New Customer</h5>
            <form onSubmit={create}>
              <div className="row g-3">
                <div className="col-md-6">
                  <label className="form-label">Name</label>
                  <input className="form-control" required value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} />
                </div>
                <div className="col-md-2">
                  <label className="form-label">Country (ISO2)</label>
                  <input className="form-control text-uppercase" placeholder="SA" value={form.country||''} onChange={e=>setForm(f=>({...f,country:e.target.value.toUpperCase()}))} />
                </div>
                <div className="col-md-4">
                  <label className="form-label">Type</label>
                  <select className="form-select" value={form.type||''} onChange={e=>setForm(f=>({...f,type:e.target.value||null}))}>
                    <option value="">--</option>
                    {TYPES.map(t=><option key={t.value} value={t.value}>{t.label}</option>)}
                  </select>
                </div>

                <div className="col-md-6">
                  <label className="form-label">Commercial Registration</label>
                  <input className="form-control" value={form.commercial_registration||''} onChange={e=>setForm(f=>({...f,commercial_registration:e.target.value}))} />
                </div>
                <div className="col-md-6">
                  <label className="form-label">VAT Number</label>
                  <input className="form-control" value={form.vat_number||''} onChange={e=>setForm(f=>({...f,vat_number:e.target.value}))} />
                </div>

                <div className="col-12 mt-2">
                  <h6 className="mb-2">Contacts</h6>
                  <div className="row g-2 align-items-end">
                    <div className="col-md-3">
                      <label className="form-label">Role</label>
                      <input className="form-control" value={contact.role} onChange={e=>setContact(c=>({...c,role:e.target.value}))} />
                    </div>
                    <div className="col-md-3">
                      <label className="form-label">Name</label>
                      <input className="form-control" value={contact.name} onChange={e=>setContact(c=>({...c,name:e.target.value}))} />
                    </div>
                    <div className="col-md-3">
                      <label className="form-label">Email</label>
                      <input className="form-control" type="email" value={contact.email} onChange={e=>setContact(c=>({...c,email:e.target.value}))} />
                    </div>
                    <div className="col-md-2">
                      <label className="form-label">Phone</label>
                      <input className="form-control" value={contact.phone} onChange={e=>setContact(c=>({...c,phone:e.target.value}))} />
                    </div>
                    <div className="col-md-1">
                      <button type="button" className="btn btn-outline-secondary w-100" onClick={addContact}>Add</button>
                    </div>
                  </div>

                  {(form.contacts||[]).length ? (
                    <div className="table-responsive mt-3">
                      <table className="table table-sm table-striped">
                        <thead><tr><th>Role</th><th>Name</th><th>Email</th><th>Phone</th></tr></thead>
                        <tbody>
                          {form.contacts.map((c,i)=>(<tr key={i}><td>{c.role}</td><td>{c.name}</td><td>{c.email}</td><td>{c.phone}</td></tr>))}
                        </tbody>
                      </table>
                    </div>
                  ): null}
                </div>

                <div className="col-12">
                  <button className="btn btn-primary">Create Customer</button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="table-responsive shadow-sm">
        <table className="table table-sm table-striped align-middle">
          <thead><tr><th>Name</th><th>Country</th><th>Type</th><th>CR</th><th>VAT</th><th>#Contacts</th></tr></thead>
          <tbody>
            {rows.map(r => (
              <tr key={r.id}>
                <td>{r.name}</td>
                <td>{r.country || ''}</td>
                <td>{r.type || ''}</td>
                <td>{r.commercial_registration || ''}</td>
                <td>{r.vat_number || ''}</td>
                <td>{r.contacts_count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
JSX

# ---------- Config (kept simple) ----------
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
      const { data } = await api.get('/config/options', { params: { types: 'segments,service_lines,partners,statuses' } })
      setData(data)
    }
    load()
  }, [])
  return (
    <div>
      <h2 className="mb-3">Dropdowns & Statuses</h2>
      <Editor title="Segments" type="segments" rows={data.segments} setRows={rows=>setData(s=>({...s, segments: rows}))} />
      <Editor title="Service Lines" type="service_lines" rows={data.service_lines} setRows={rows=>setData(s=>({...s, service_lines: rows}))} />
      <Editor title="Partners" type="partners" rows={data.partners} setRows={rows=>setData(s=>({...s, partners: rows}))} />
      <Editor title="Statuses" type="statuses" rows={data.statuses} setRows={rows=>setData(s=>({...s, statuses: rows}))} />
    </div>
  )
}
JSX

# ---------- Project Terms (sum must be 100%) ----------
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

# ---------- main.jsx routes ----------
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
          <Route path="customers" element={<Customers />} />
          <Route path="config" element={<Config />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </AuthProvider>
)
JSX

# ---------- Ensure backend terms route is mounted ----------
if ! grep -q "projects/:id/terms" "$BACK/src/server.js"; then
  grep -q "import projectTermsRoutes" "$BACK/src/server.js" || \
    sed -i "1 a import projectTermsRoutes from './routes/projectTerms.js';" "$BACK/src/server.js"
  sed -i "/app.use(.*api\\/auth/a app.use('/api/projects/:id/terms', projectTermsRoutes);" "$BACK/src/server.js" || true
fi

# ---------- Rebuild & restart servers ----------
cd "$FRONT"
npm run build

pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

pkill -f "node src/server.js" 2>/dev/null || true
cd "$BACK"
nohup npm start >/dev/null 2>&1 &

echo "UI reset deployed. Open / and click 'Manage Terms' in the Projects table."
