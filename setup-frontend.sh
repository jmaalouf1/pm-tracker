set -euo pipefail
BASE=~/projects/frontend
rm -rf "$BASE"
mkdir -p "$BASE/src/pages" "$BASE/src/components" "$BASE/src/context" "$BASE/src/services"

cat > "$BASE/package.json" <<'JSON'
{
  "name": "pm-tracker-frontend",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173"
  },
  "dependencies": {
    "axios": "^1.7.4",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.26.1"
  },
  "devDependencies": {
    "vite": "^5.4.1",
    "@vitejs/plugin-react": "^4.3.1"
  }
}
JSON

cat > "$BASE/vite.config.js" <<'JS'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig({ plugins: [react()], server: { port: 5173 } })
JS

cat > "$BASE/index.html" <<'HTML'
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>PM Tracker</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
HTML

cat > "$BASE/src/app.css" <<'CSS'
:root { --bg:#f6f7fb; --text:#1a1d23; }
html,body,#root { height:100%; }
body { margin:0; background:var(--bg); color:var(--text);
  font-family: system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,"Noto Sans","Apple Color Emoji","Segoe UI Emoji"; }
.container { max-width:420px; margin:12vh auto; padding:24px; background:#fff;
  border:1px solid #e5e7eb; border-radius:12px; box-shadow:0 4px 20px rgba(0,0,0,.04); }
label { display:block; margin:12px 0 4px; font-weight:600; }
input,select { width:100%; padding:10px 12px; border:1px solid #d1d5db; border-radius:8px; background:#fff; }
button { margin-top:12px; padding:10px 14px; border-radius:8px; border:0; background:#2563eb; color:#fff; font-weight:600; cursor:pointer; }
button[disabled]{ opacity:.6; cursor:not-allowed; }
.error { color:#b91c1c; margin-top:8px; display:block; }
.wrapper { display:flex; min-height:100vh; }
aside { width:260px; border-right:1px solid #e5e7eb; padding:16px; background:#fff; }
main { flex:1; padding:24px; }
table { width:100%; border-collapse:collapse; background:#fff; }
th,td { border:1px solid #e5e7eb; padding:8px 10px; }
thead th { background:#f3f4f6; position:sticky; top:0; }
nav ul { list-style:none; padding:0; margin:.25rem 0 1rem; }
nav li { margin:.25rem 0; }
CSS

cat > "$BASE/src/services/api.js" <<'JS'
import axios from 'axios';
function computeBase() {
  const env = (import.meta.env.VITE_API_BASE_URL || '').trim();
  if (env) return env;
  const { protocol, hostname } = window.location;
  return `${protocol}//${hostname}:8080/api`;
}
const api = axios.create({ baseURL: computeBase(), timeout: 15000 });
api.interceptors.request.use(cfg => {
  const token = localStorage.getItem('accessToken');
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});
api.interceptors.response.use(r => r, err => {
  const msg = err?.response?.data?.error || err?.message || 'Request failed';
  return Promise.reject(new Error(msg));
});
export default api;
JS

cat > "$BASE/src/context/AuthContext.jsx" <<'JSX'
import React, { createContext, useContext, useState } from 'react'
import api from '../services/api'
const Ctx = createContext(null)
export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  async function login(email, password) {
    const { data } = await api.post('/auth/login', { email, password })
    localStorage.setItem('accessToken', data.accessToken)
    localStorage.setItem('refreshToken', data.refreshToken)
    setUser(data.user)
  }
  function logout() {
    const rt = localStorage.getItem('refreshToken')
    api.post('/auth/logout', { refreshToken: rt }).catch(()=>{})
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    setUser(null)
  }
  return <Ctx.Provider value={{ user, login, logout }}>{children}</Ctx.Provider>
}
export const useAuth = () => useContext(Ctx)
JSX

cat > "$BASE/src/components/Layout.jsx" <<'JSX'
import React from 'react'
import { Link, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
export default function Layout() {
  const { logout } = useAuth()
  const loc = useLocation()
  return (
    <div className="wrapper">
      <aside>
        <h2>PM Tracker</h2>
        <nav>
          <div><strong>Projects</strong></div>
          <ul>
            <li><Link to="/">View Projects</Link></li>
            <li><Link to="/projects/new">New Project</Link></li>
            <li><Link to="/payment-terms">Payment Terms</Link></li>
          </ul>
          <div><strong>Configuration</strong></div>
          <ul>
            <li><Link to="/config">Dropdowns & Statuses</Link></li>
          </ul>
        </nav>
        <button className="secondary" onClick={logout}>Logout</button>
      </aside>
      <main>
        <Outlet key={loc.key} />
      </main>
    </div>
  )
}
JSX

cat > "$BASE/src/pages/Login.jsx" <<'JSX'
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
    <form onSubmit={submit} className="container">
      <h2>Sign in</h2>
      <label>Email</label>
      <input autoFocus type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
      <label>Password</label>
      <input type="password" value={password} onChange={e=>setPassword(e.target.value)} required />
      {error ? <small className="error">{error}</small> : null}
      <button type="submit" disabled={busy}>{busy ? 'Signing in…' : 'Login'}</button>
    </form>
  )
}
JSX

cat > "$BASE/src/pages/ProjectsList.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'
export default function ProjectsList() {
  const [rows, setRows] = useState([])
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(false)
  async function load() {
    setLoading(true)
    const { data } = await api.get('/projects', { params: { search: query } })
    setRows(data.data); setLoading(false)
  }
  useEffect(() => { load() }, [])
  return (
    <div>
      <h2>Projects</h2>
      <div style={{ display:'flex', gap:8, marginBottom:12 }}>
        <input placeholder="Search..." value={query} onChange={e=>setQuery(e.target.value)} />
        <button onClick={load} disabled={loading}>Search</button>
      </div>
      <table>
        <thead>
          <tr><th>ID</th><th>Name</th><th>Customer</th><th>Segment</th><th>Service Line</th><th>Partner</th><th>Status</th><th>Invoice</th><th>PO</th><th>Backlog 2025</th></tr>
        </thead>
        <tbody>
          {rows.map(r => (
            <tr key={r.id}>
              <td>{r.id}</td><td>{r.name}</td><td>{r.customer||''}</td>
              <td>{r.segment||''}</td><td>{r.service_line||''}</td><td>{r.partner||''}</td>
              <td>{r.status||''}</td><td>{r.invoice_status||''}</td><td>{r.po_status||''}</td>
              <td>{Number(r.backlog_2025||0).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
JSX

cat > "$BASE/src/pages/ProjectNew.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'
export default function ProjectNew() {
  const [form, setForm] = useState({ name: '' })
  const [opts, setOpts] = useState({ customers: [], segments: [], service_lines: [], partners: [], statuses: [], payment_terms: [] })
  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,segments,service_lines,partners,statuses' } })
      const pt = await api.get('/payment-terms')
      setOpts({ ...data, payment_terms: pt.data })
    }
    load()
  }, [])
  function change(k, v) { setForm(s => ({ ...s, [k]: v })) }
  async function submit(e) { e.preventDefault(); await api.post('/projects', form); alert('Project created'); setForm({ name: '' }) }
  const dd = (name, list, extra = (o)=>o.name) => (
    <select value={form[name] || ''} onChange={e=>change(name, e.target.value || null)}>
      <option value="">--</option>
      {list.map(o => <option key={o.id} value={o.id}>{extra(o)}</option>)}
    </select>
  )
  return (
    <form onSubmit={submit} style={{ maxWidth: 600 }}>
      <h2>New Project</h2>
      <label>Name</label><input value={form.name} onChange={e=>change('name', e.target.value)} required />
      <label>Customer</label>{dd('customer_id', opts.customers)}
      <label>Segment</label>{dd('segment_id', opts.segments)}
      <label>Service Line</label>{dd('service_line_id', opts.service_lines)}
      <label>Partner</label>{dd('partner_id', opts.partners)}
      <label>Payment Terms</label>{dd('payment_term_id', opts.payment_terms, o => `${o.name} (${o.days}d)`)}
      <label>Status</label>{dd('status_id', opts.statuses.filter(s=>s.type==='project_status'))}
      <label>PO Status</label>{dd('po_status_id', opts.statuses.filter(s=>s.type==='po_status'))}
      <label>Invoice Status</label>{dd('invoice_status_id', opts.statuses.filter(s=>s.type==='invoice_status'))}
      <label>Backlog 2025</label><input type="number" step="0.01" value={form.backlog_2025 || ''} onChange={e=>change('backlog_2025', e.target.value)} />
      <button type="submit">Create</button>
    </form>
  )
}
JSX

cat > "$BASE/src/pages/PaymentTerms.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'
export default function PaymentTerms() {
  const [rows, setRows] = useState([])
  const [form, setForm] = useState({ name: '', days: 0, description: '' })
  async function load() { const { data } = await api.get('/payment-terms'); setRows(data) }
  useEffect(() => { load() }, [])
  async function add(e) { e.preventDefault(); await api.post('/payment-terms', form); setForm({ name:'', days:0, description:'' }); await load() }
  async function save(r) { await api.put('/payment-terms/'+r.id, r); await load() }
  async function remove(id) { if (!confirm('Delete?')) return; await api.delete('/payment-terms/'+id); await load() }
  return (
    <div>
      <h2>Payment Terms</h2>
      <form onSubmit={add} style={{ display:'flex', gap:8, marginBottom:12 }}>
        <input placeholder="Name" value={form.name} onChange={e=>setForm(s=>({...s,name:e.target.value}))} required />
        <input type="number" placeholder="Days" value={form.days} onChange={e=>setForm(s=>({...s,days:+e.target.value}))} />
        <input placeholder="Description" value={form.description} onChange={e=>setForm(s=>({...s,description:e.target.value}))} />
        <button>Add</button>
      </form>
      <table>
        <thead><tr><th>Name</th><th>Days</th><th>Description</th><th>Actions</th></tr></thead>
        <tbody>
          {rows.map(r => (
            <tr key={r.id}>
              <td><input value={r.name} onChange={e=>setRows(rs=>rs.map(x=>x.id===r.id?{...x,name:e.target.value}:x))} /></td>
              <td><input type="number" value={r.days} onChange={e=>setRows(rs=>rs.map(x=>x.id===r.id?{...x,days:+e.target.value}:x))} /></td>
              <td><input value={r.description || ''} onChange={e=>setRows(rs=>rs.map(x=>x.id===r.id?{...x,description:e.target.value}:x))} /></td>
              <td>
                <button onClick={()=>save(r)}>Save</button>
                <button onClick={()=>remove(r.id)}>Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
JSX

cat > "$BASE/src/pages/Config.jsx" <<'JSX'
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
    <div style={{ marginBottom: 24 }}>
      <h3>{title}</h3>
      <div style={{ display:'flex', gap:8, marginBottom:8 }}>
        {type === 'statuses' ? (
          <select value={statusType} onChange={e=>setStatusType(e.target.value)}>
            <option value="project_status">Project Status</option>
            <option value="invoice_status">Invoice Status</option>
            <option value="po_status">PO Status</option>
          </select>
        ) : null}
        <input placeholder="Name" value={name} onChange={e=>setName(e.target.value)} />
        <button onClick={add}>Add</button>
      </div>
      <table>
        <thead><tr><th>Name</th><th>Active</th><th>Save</th></tr></thead>
        <tbody>
          {rows.map(r => (
            <tr key={r.id}>
              <td><input value={r.name} onChange={e=>setRows(list=>list.map(x=>x.id===r.id?{...x,name:e.target.value}:x))} /></td>
              <td><input type="checkbox" checked={!!r.is_active} onChange={e=>setRows(list=>list.map(x=>x.id===r.id?{...x,is_active:e.target.checked?1:0}:x))} /></td>
              <td><button onClick={()=>save(r)}>Save</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
export default function Config() {
  const [data, setData] = useState({ customers: [], segments: [], service_lines: [], partners: [], statuses: [] })
  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,segments,service_lines,partners,statuses' } })
      setData(data)
    }
    load()
  }, [])
  return (
    <div>
      <h2>Dropdowns & Statuses</h2>
      <Editor title="Customers" type="customers" rows={data.customers} setRows={rows=>setData(s=>({...s, customers: rows}))} />
      <Editor title="Segments" type="segments" rows={data.segments} setRows={rows=>setData(s=>({...s, segments: rows}))} />
      <Editor title="Service Lines" type="service_lines" rows={data.service_lines} setRows={rows=>setData(s=>({...s, service_lines: rows}))} />
      <Editor title="Partners" type="partners" rows={data.partners} setRows={rows=>setData(s=>({...s, partners: rows}))} />
      <Editor title="Statuses" type="statuses" rows={data.statuses} setRows={rows=>setData(s=>({...s, statuses: rows}))} />
    </div>
  )
}
JSX

cat > "$BASE/src/main.jsx" <<'JSX'
import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Layout from './components/Layout'
import Login from './pages/Login'
import ProjectsList from './pages/ProjectsList'
import ProjectNew from './pages/ProjectNew'
import PaymentTerms from './pages/PaymentTerms'
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
          <Route path="payment-terms" element={<PaymentTerms />} />
          <Route path="config" element={<Config />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </AuthProvider>
)
JSX
