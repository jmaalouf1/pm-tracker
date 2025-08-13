set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

############################
# 1) Clean, minimal global CSS (no fixed header, no icons)
############################
cat > "$SRC/app.css" <<'CSS'
:root{
  --brand:#1f6feb; --brand-700:#1a5fd1;
  --bg:#f7f9fc; --card:#ffffff; --text:#0f172a; --muted:#64748b;
  --radius:12px; --shadow:0 4px 14px rgba(16,24,40,.08);
}
html,body{background:var(--bg); color:var(--text); min-height:100%;}
/* Simple, non-fixed navbar */
.navbar{
  background:linear-gradient(90deg,var(--brand),var(--brand-700));
  box-shadow:var(--shadow);
  padding:.5rem 0;
}
.navbar .navbar-brand,.navbar .nav-link{color:#fff !important}
.navbar .navbar-brand{font-weight:800; letter-spacing:.2px}
.navbar .nav-link{padding:.35rem .6rem}

.container-page{max-width:1200px; margin-inline:auto; padding:20px;}
.card{border:none; border-radius:var(--radius); background:var(--card); box-shadow:var(--shadow);}

.table thead th{position:sticky; top:0; background:#fff; z-index:1}
.footer-copy{color:#6b7280; font-size:.86rem; text-align:center; padding:16px 0 24px}

/* Login layout */
.login-wrap{display:grid; grid-template-columns:1fr; gap:24px; min-height:calc(100vh - 80px); align-items:center}
@media (min-width: 992px){ .login-wrap{ grid-template-columns: 1.1fr 0.9fr; } }
.login-hero{display:none}
@media (min-width: 992px){
  .login-hero{
    display:block; margin:10px 10px 10px 0; padding:28px; border-radius:16px;
    background:linear-gradient(135deg, #eef3ff, #f7fbff);
    box-shadow:var(--shadow);
  }
}
.login-hero h1{font-weight:800; margin-bottom:8px}
.login-hero p{color:var(--muted)}
.login-panel{width:100%; max-width:420px; background:var(--card); border-radius:14px; box-shadow:var(--shadow); padding:22px}
.copy-muted{color:#94a3b8; font-size:.92rem}

/* Pagination */
.pagination .btn{min-width:84px}
CSS

############################
# 2) Navbar/Layout – text-only, non-fixed, jump on the right
############################
cat > "$SRC/components/Layout.jsx" <<'JSX'
import React, { useState } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import '../app.css'

export default function Layout() {
  const nav = useNavigate()
  const { user, logout } = useAuth()
  const [jump, setJump] = useState('')

  function onJump(e){
    e.preventDefault()
    const s = jump.trim().toLowerCase()
    if (!s) return
    if (s.startsWith('terms ')) { const id=s.replace(/\D+/g,''); if(id) return nav(`/projects/${id}/terms`) }
    if (s.includes('payment')) return nav('/project-terms')
    if (s.includes('users')) return nav('/users')
    if (s.includes('customers')) return nav('/customers')
    return nav('/')
  }

  async function doLogout(e){
    e.preventDefault()
    try { await logout() } finally { nav('/login', { replace:true }) }
  }

  return (
    <>
      <nav className="navbar navbar-expand-lg">
        <div className="container-page">
          <Link className="navbar-brand" to="/">PM Tracker</Link>
          <button className="navbar-toggler btn btn-light btn-sm" type="button" data-bs-toggle="collapse" data-bs-target="#nav">Menu</button>
          <div id="nav" className="collapse navbar-collapse">
            <ul className="navbar-nav me-3">
              <li className="nav-item dropdown">
                <span className="nav-link dropdown-toggle" role="button" data-bs-toggle="dropdown">Projects</span>
                <ul className="dropdown-menu">
                  <li><NavLink className="dropdown-item" to="/">View Projects</NavLink></li>
                  <li><NavLink className="dropdown-item" to="/projects/new">New Project</NavLink></li>
                  <li><NavLink className="dropdown-item" to="/project-terms">Payment Terms</NavLink></li>
                </ul>
              </li>
              <li className="nav-item"><NavLink className="nav-link" to="/customers">Customers</NavLink></li>
              <li className="nav-item"><NavLink className="nav-link" to="/config">Config</NavLink></li>
              <li className="nav-item"><NavLink className="nav-link" to="/users">Users</NavLink></li>
            </ul>

            <form className="ms-auto d-flex me-3" onSubmit={onJump}>
              <input className="form-control" style={{width:360}} placeholder="Jump: terms 12 / payment terms / users"
                     value={jump} onChange={e=>setJump(e.target.value)} />
            </form>

            <div className="dropdown">
              <button className="btn btn-sm btn-light dropdown-toggle" data-bs-toggle="dropdown">
                {user?.name || 'Account'}
              </button>
              <ul className="dropdown-menu dropdown-menu-end">
                <li className="dropdown-item text-muted" style={{fontSize:'.85rem'}}>{user?.email || ''}</li>
                <li><hr className="dropdown-divider" /></li>
                <li><a className="dropdown-item" href="#" onClick={doLogout}>Sign out</a></li>
              </ul>
            </div>
          </div>
        </div>
      </nav>

      <main className="container-page">
        <Outlet />
        <div className="mt-4 footer-copy">(c) 2025 PM Tracker. All rights reserved.</div>
      </main>
    </>
  )
}
JSX

############################
# 3) Login – right card, tidy copy, **no icons**
############################
cat > "$SRC/pages/Login.jsx" <<'JSX'
import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import '../app.css'

export default function Login() {
  const [email, setEmail] = useState('admin@example.com')
  const [password, setPassword] = useState('Admin@12345')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const { login, user } = useAuth()
  const nav = useNavigate()
  useEffect(()=>{ if(user) nav('/') },[user])

  async function submit(e) {
    e.preventDefault(); setBusy(true); setError('')
    try { await login(email, password); nav('/') }
    catch (e) { setError(e.message || 'Login failed') }
    finally { setBusy(false) }
  }

  return (
    <>
      <div className="login-wrap">
        <div className="login-hero">
          <h1>Track projects, terms and cashflow in one place</h1>
          <p>Create projects with milestones, update term statuses quickly, and keep finance and delivery in sync.</p>
          <ul className="mt-3" style={{color:'#5b677a'}}>
            <li>Instant search across projects and customers</li>
            <li>Payment terms with validation and status updates</li>
            <li>PM assignments that show only what each PM owns</li>
          </ul>
        </div>

        <div className="d-flex justify-content-center">
          <div className="login-panel">
            <div className="mb-3">
              <div className="fw-bold">PM Tracker</div>
              <div className="copy-muted small">Sign in to your workspace</div>
            </div>

            <form onSubmit={submit}>
              <div className="mb-3">
                <label className="form-label fw-bold">Email</label>
                <input className="form-control" type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
              </div>
              <div className="mb-2">
                <label className="form-label fw-bold">Password</label>
                <input className="form-control" type="password" value={password} onChange={e=>setPassword(e.target.value)} required />
              </div>
              {error ? <div className="text-danger small mb-2">{error}</div> : <div className="form-text">Use your PM Tracker credentials.</div>}
              <button className="btn btn-primary w-100 mt-2" disabled={busy}>{busy ? 'Signing in...' : 'Sign in'}</button>
            </form>
          </div>
        </div>
      </div>

      <div className="footer-copy">(c) 2025 PM Tracker. All rights reserved.</div>
    </>
  )
}
JSX

############################
# 4) Pagination – **text-only** controls (no icons)
############################
cat > "$SRC/components/Pagination.jsx" <<'JSX'
import React from 'react'
export default function Pagination({page, pages, total, pageSize, setPage, setPageSize}){
  const canPrev = page > 1
  const canNext = page < pages
  return (
    <div className="d-flex justify-content-between align-items-center mt-3">
      <div className="d-flex align-items-center gap-2">
        <span className="text-muted">Rows:</span>
        <select className="form-select form-select-sm" style={{width:'auto'}}
                value={pageSize} onChange={e=>setPageSize(Number(e.target.value))}>
          {[10,20,50,100].map(n => <option key={n} value={n}>{n}</option>)}
        </select>
        <span className="text-muted">Total: {total}</span>
      </div>
      <div className="btn-group">
        <button className="btn btn-sm btn-outline-secondary" disabled={!canPrev} onClick={()=>setPage(1)}>First</button>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canPrev} onClick={()=>setPage(page-1)}>Prev</button>
        <span className="btn btn-sm btn-light disabled">{page} / {pages}</span>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canNext} onClick={()=>setPage(page+1)}>Next</button>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canNext} onClick={()=>setPage(pages)}>Last</button>
      </div>
    </div>
  )
}
JSX

############################
# 5) Remove any leftover <i ...> tags (icons) in all JSX files
############################
find "$SRC" -type f -name "*.jsx" -print0 | xargs -0 sed -i -E 's#<i[^>]*></i>##g'

############################
# 6) Build & re-serve
############################
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "Baseline UI applied. Do a HARD refresh (Ctrl/Cmd+Shift+R)."
