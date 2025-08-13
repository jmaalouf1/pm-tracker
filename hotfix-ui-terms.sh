set -euo pipefail

FRONT=~/projects/frontend/src
BACK=~/projects/backend/src

mkdir -p "$FRONT/components" "$FRONT/pages"

# ---------- Global styles (fixes inputs spilling, cards, topbar)
cat > "$FRONT/app.css" <<'CSS'
:root { --bg:#f7f8fc; --ink:#111827; --muted:#6b7280; --primary:#1f4bec; --border:#e5e7eb; }
html,body,#root { height:100%; }
body { margin:0; background:var(--bg); color:var(--ink);
  font-family: system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,"Noto Sans","Apple Color Emoji","Segoe UI Emoji"; }
.container { max-width:420px; margin:12vh auto; padding:24px; background:#fff;
  border:1px solid var(--border); border-radius:12px; box-shadow:0 6px 24px rgba(0,0,0,.05); }
h1,h2,h3 { margin:0 0 12px; }
label { display:block; margin:12px 0 6px; font-weight:600; }
input, select, textarea {
  width:100%; padding:10px 12px; border:1px solid var(--border);
  border-radius:10px; outline:none; background:#fff; font-size:14px;
}
input:focus, select:focus, textarea:focus { border-color:#c7d2fe; box-shadow:0 0 0 3px rgba(99,102,241,.2); }
button, .btn { display:inline-flex; align-items:center; gap:8px; border:0; border-radius:10px; padding:10px 14px; font-weight:600; cursor:pointer; }
button.primary, .btn.primary { background:var(--primary); color:#fff; }
button.ghost { background:#fff; border:1px solid var(--border); color:var(--ink); }
small.error { color:#b91c1c; display:block; margin-top:8px; }
.topbar { display:flex; align-items:center; gap:16px; padding:10px 16px; background:var(--primary); color:#fff; position:sticky; top:0; z-index:20; }
.topbar a { color:#fff; text-decoration:none; }
.brand { font-weight:800; font-size:18px; }
.menu { display:flex; gap:16px; align-items:center; }
.dropdown { position:relative; cursor:default; }
.dropdown-menu { display:none; position:absolute; top:100%; left:0; background:#fff; color:#111; border:1px solid var(--border); border-radius:10px; padding:8px; min-width:200px; }
.dropdown:hover .dropdown-menu { display:flex; flex-direction:column; }
.dropdown-menu a { color:#111; padding:8px 10px; border-radius:8px; }
.dropdown-menu a:hover { background:#f3f4f6; }
.quick input { border-radius:10px; border:0; padding:9px 12px; min-width:280px; }
.logout { margin-left:auto; }
.shell { min-height:100vh; }
.content { padding:20px; max-width:1200px; margin:0 auto; }
.card { background:#fff; border:1px solid var(--border); border-radius:12px; padding:16px; box-shadow:0 6px 24px rgba(0,0,0,.04); }
.grid { display:grid; grid-template-columns: repeat(12, 1fr); gap:12px; }
.col-12 { grid-column: span 12; } .col-8 { grid-column: span 8; } .col-6 { grid-column: span 6; } .col-4 { grid-column: span 4; } .col-3 { grid-column: span 3; } .col-2 { grid-column: span 2; } .col-1 { grid-column: span 1; }
table { width:100%; border-collapse:collapse; background:#fff; }
th,td { border:1px solid var(--border); padding:10px 12px; font-size:14px; }
thead th { background:#f3f4f6; position:sticky; top:0; }
.align-right { text-align:right; }
CSS

# ---------- Top nav layout + quick search
cat > "$FRONT/components/Layout.jsx" <<'JSX'
import React, { useState } from 'react'
import { Link, Outlet, useNavigate } from 'react-router-dom'
import '../app.css'

export default function Layout() {
  const nav = useNavigate()
  const [q, setQ] = useState('')
  function go(e) {
    e.preventDefault()
    const s = q.trim().toLowerCase()
    if (!s) return
    if (s.includes('new project')) return nav('/projects/new')
    if (s.startsWith('terms')) { const id = s.replace(/\D+/g, ''); if (id) return nav(`/projects/${id}/terms`) }
    if (s.includes('customers')) return nav('/customers')
    if (s.includes('config') || s.includes('status')) return nav('/config')
    return nav('/')
  }
  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand"><Link to="/">PM Tracker</Link></div>
        <nav className="menu">
          <div className="dropdown">
            <span>Projects ?</span>
            <div className="dropdown-menu">
              <Link to="/">View Projects</Link>
              <Link to="/projects/new">New Project</Link>
            </div>
          </div>
          <Link to="/customers">Customers</Link>
          <Link to="/config">Config</Link>
        </nav>
        <form onSubmit={go} className="quick">
          <input placeholder="Search or jump (e.g. 'terms 12')" value={q} onChange={e=>setQ(e.target.value)} />
        </form>
        <Link className="btn ghost logout" to="/login">Logout</Link>
      </header>
      <main className="content">
        <Outlet />
      </main>
    </div>
  )
}
JSX

# ---------- Login card clean-up (keeps inputs inside)
cat > "$FRONT/pages/Login.jsx" <<'JSX'
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
      <button className="primary" type="submit" disabled={busy}>{busy ? 'Signing in…' : 'Login'}</button>
    </form>
  )
}
JSX

# ---------- Projects list (shows Remaining % + Backlog, and Manage Terms)
cat > "$FRONT/pages/ProjectsList.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { Link } from 'react-router-dom'

export default function ProjectsList() {
  const [rows, setRows] = useState([])
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(false)

  async function load() {
    setLoading(true)
    const { data } = await api.get('/projects', { params: { search: query } })
    setRows(data.data)
    setLoading(false)
  }
  useEffect(() => { load() }, [])

  return (
    <div>
      <h2>Projects</h2>
      <div style={{ display:'flex', gap:8, marginBottom:12 }}>
        <input placeholder="Search..." value={query} onChange={e=>setQuery(e.target.value)} />
        <button onClick={load} disabled={loading}>Search</button>
        <Link className="btn primary" to="/projects/new">New Project</Link>
      </div>
      <div className="card">
        <table>
          <thead>
            <tr>
              <th>ID</th><th>Name</th><th>Customer</th><th>Segment</th><th>Status</th>
              <th>Remaining %</th><th>Backlog</th><th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(r => (
              <tr key={r.id}>
                <td>{r.id}</td>
                <td>{r.name}</td>
                <td>{r.customer || ''}</td>
                <td>{r.segment || ''}</td>
                <td>{r.status || ''}</td>
                <td className="align-right">{Number(r.remaining_percent||0).toFixed(2)}%</td>
                <td className="align-right">{Number(r.backlog_amount||0).toLocaleString(undefined,{minimumFractionDigits:2, maximumFractionDigits:2})}</td>
                <td><Link to={`/projects/${r.id}/terms`}>Manage Terms</Link></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
JSX

# ---------- Project Terms page (robust validation and totals)
cat > "$FRONT/pages/ProjectTerms.jsx" <<'JSX'
import React, { useEffect, useMemo, useState } from 'react'
import api from '../services/api'
import { useParams } from 'react-router-dom'

function clampPct(n){ n = Number(n||0); if(isNaN(n)) n=0; return Math.max(0, Math.min(100, n)) }

export default function ProjectTerms() {
  const { id } = useParams()
  const [terms, setTerms] = useState([])
  const [statuses, setStatuses] = useState([])
  const [project, setProject] = useState(null)
  const [msg, setMsg] = useState('')

  const total = useMemo(()=> terms.reduce((a,b)=> a + clampPct(b.percentage), 0), [terms])
  const valid = Math.abs(total - 100) <= 0.01 && terms.every(t => (t.description||'').trim().length)

  async function load() {
    const p = await api.get('/projects/' + id); setProject(p.data)
    const list = await api.get(`/projects/${id}/terms`)
    setTerms(list.data.length ? list.data : [{ percentage: 100, description: 'Milestone 1', status_id: null }])
    const opt = await api.get('/config/options', { params: { types: 'statuses' } })
    setStatuses(opt.data.statuses.filter(s=>s.type==='term_status'))
  }

  useEffect(()=>{ load() }, [id])

  function addRow(){ setTerms(ts=>[...ts, { percentage: 0, description: '', status_id: null }]) }
  function update(i,k,v){ setTerms(ts=>ts.map((t,idx)=> idx===i? {...t, [k]:k==='percentage'? clampPct(v): v }: t)) }
  function del(i){ setTerms(ts=> ts.filter((_,idx)=> idx!==i)) }

  async function save(){
    setMsg('')
    if(!valid){ setMsg('Fix issues: ensure descriptions are filled and total = 100%. Current total: ' + total.toFixed(2) + '%'); return }
    await api.put(`/projects/${id}/terms`, { terms: terms.map((t,idx)=> ({ ...t, seq: idx+1, percentage: clampPct(t.percentage) })) })
    setMsg('Saved'); await load()
  }

  return (
    <div>
      <h2>Project Terms {project ? '— ' + project.name : ''}</h2>
      <div className="card">
        <table>
          <thead><tr><th>#</th><th className="align-right">%</th><th>Description</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            {terms.map((t,i)=>(
              <tr key={i}>
                <td>{i+1}</td>
                <td className="align-right"><input type="number" min="0" max="100" step="0.01" value={t.percentage} onChange={e=>update(i,'percentage',e.target.value)} /></td>
                <td><input value={t.description} onChange={e=>update(i,'description',e.target.value)} placeholder="e.g. UAT sign-off" /></td>
                <td>
                  <select value={t.status_id || ''} onChange={e=>update(i,'status_id', e.target.value ? Number(e.target.value) : null)}>
                    <option value="">--</option>
                    {statuses.map(s=> <option key={s.id} value={s.id}>{s.name}</option>)}
                  </select>
                </td>
                <td><button className="ghost" onClick={()=>del(i)}>Remove</button></td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr><th>Total</th><th className="align-right">{total.toFixed(2)}%</th><th colSpan="3"></th></tr>
          </tfoot>
        </table>
        <div style={{ display:'flex', gap:8, marginTop:10 }}>
          <button onClick={addRow}>Add Row</button>
          <button className="primary" onClick={save} disabled={!valid}>Save Terms</button>
          {msg && <span style={{marginLeft:8}}>{msg}</span>}
        </div>
      </div>
    </div>
  )
}
JSX

# ---------- Backend: tighten/normalize terms validation (sum=100 with tolerance, clamp 0..100)
mkdir -p "$BACK/controllers"
cat > "$BACK/controllers/projectTermsController.js" <<'JS'
import { pool } from '../db.js';

function pct(n){ n = Number(n); if(isNaN(n)) return 0; return Math.max(0, Math.min(100, n)); }

export const ProjectTermsController = {
  async list(req, res) {
    const { id } = req.params;
    const [rows] = await pool.query(
      `SELECT t.*, s.name AS status
         FROM project_terms t
         LEFT JOIN statuses s ON s.id = t.status_id
        WHERE t.project_id = ?
        ORDER BY t.seq, t.id`, [id]);
    res.json(rows);
  },
  async replaceAll(req, res) {
    const { id } = req.params;
    const { terms } = req.body || {};
    if (!Array.isArray(terms) || !terms.length) return res.status(400).json({ error: 'terms array required' });
    let sum = 0;
    for (const t of terms) {
      const p = pct(t.percentage);
      if (!(p >= 0 && p <= 100)) return res.status(400).json({ error: 'percentage must be between 0 and 100' });
      if (!t.description || !String(t.description).trim()) return res.status(400).json({ error: 'description required for each term' });
      sum += p;
    }
    if (Math.abs(sum - 100) > 0.01) return res.status(400).json({ error: 'Sum of percentages must equal 100%' });

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      await conn.query('DELETE FROM project_terms WHERE project_id = ?', [id]);
      let seq = 1;
      for (const t of terms) {
        await conn.query(
          'INSERT INTO project_terms (project_id, seq, percentage, description, status_id) VALUES (?,?,?,?,?)',
          [id, seq++, pct(t.percentage), t.description, t.status_id || null]
        );
      }
      await conn.commit();
    } catch (e) {
      await conn.rollback();
      throw e;
    } finally {
      conn.release();
    }
    res.json({ ok: true });
  }
};
JS

echo "Hotfix files written."

# ---------- Rebuild frontend & restart backend
cd ~/projects/frontend
npm run build

# If you run the static server manually:
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

# Restart API (foreground users can skip these pkill lines)
pkill -f "node src/server.js" 2>/dev/null || true
cd ~/projects/backend
nohup npm start >/dev/null 2>&1 &

echo "Hotfix deployed."
