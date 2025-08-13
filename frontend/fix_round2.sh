set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

# Ensure Bootstrap Icons CSS present
if ! grep -q 'bootstrap-icons' "$FRONT/index.html"; then
  sed -i 's#</head>#  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">\n</head>#' "$FRONT/index.html"
fi

########################################
# 1) Global CSS: thinner navbar; safe icons; login layout
########################################
cat > "$SRC/app.css" <<'CSS'
:root{
  --brand:#1f6feb; --brand-700:#1a5fd1;
  --bg:#f7f9fc; --card:#ffffff; --text:#0f172a; --muted:#64748b;
  --radius:14px; --shadow:0 6px 18px rgba(16,24,40,.07);
}
html,body{background:var(--bg); color:var(--text); min-height:100%;}
/* Fixed, slimmer navbar with proper offset */
.navbar.fixed-top{
  position:fixed; top:0; left:0; right:0; z-index:1030;
  background:linear-gradient(90deg,var(--brand),var(--brand-700));
  box-shadow:var(--shadow);
  padding-top:.35rem; padding-bottom:.35rem;  /* thinner */
}
body.has-fixed-nav main{margin-top:64px;}  /* push content below header */

.navbar .navbar-brand,.navbar .nav-link{color:#fff !important}
.navbar .navbar-brand{font-weight:800; letter-spacing:.2px; display:flex; align-items:center}
.navbar .navbar-brand i{font-size:1.15rem; margin-right:.5rem}
.navbar .nav-link{padding:.35rem .6rem}
.container-page{max-width:1200px; margin-inline:auto; padding:20px;}
.card{border:none; border-radius:var(--radius); background:var(--card); box-shadow:var(--shadow);}
.table thead th{position:sticky; top:0; background:#fff; z-index:1}
.input-icon{position:relative}
.input-icon .bi{position:absolute; left:12px; top:50%; transform:translateY(-50%); opacity:.55}
.input-icon input{padding-left:38px}

/* Pagination buttons */
.pagination .btn{min-width:84px}

/* Footer */
.footer-copy{color:#6b7280; font-size:.86rem; text-align:center; padding:16px 0 24px}

/******** Login ********/
.login-wrap{
  display:grid; grid-template-columns:1fr; min-height:calc(100vh - 64px);
  gap:24px; align-items:center;
}
@media (min-width: 992px){
  .login-wrap{ grid-template-columns: 1.1fr 0.9fr; }
}
.login-hero{
  display:none;
}
@media (min-width: 992px){
  .login-hero{
    display:block; margin:20px; padding:40px; border-radius:22px;
    background:
      radial-gradient(900px 350px at -10% -10%, rgba(255,255,255,.35) 0%, rgba(255,255,255,0) 60%),
      linear-gradient(135deg, #e8f0ff, #f7fbff 50%, #f3f7ff);
    box-shadow:var(--shadow);
  }
}
.login-hero h1{font-weight:800; margin-bottom:10px}
.login-hero p{color:var(--muted)}
.badge-pill{display:inline-flex; gap:.45rem; align-items:center; border-radius:999px; background:#eef2ff; color:#334155; padding:.45rem .75rem; margin:0 .4rem .4rem 0}

.login-card{display:flex; justify-content:center; align-items:center; padding:20px}
.login-panel{width:100%; max-width:440px; background:var(--card); border-radius:18px; box-shadow:var(--shadow); padding:26px}
.copy-muted{color:#94a3b8; font-size:.92rem}
CSS

########################################
# 2) Layout.jsx: fixed-top, right-aligned jump, user menu with Sign out
########################################
cat > "$SRC/components/Layout.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import '../app.css'

export default function Layout() {
  const nav = useNavigate()
  const { user, logout } = useAuth()
  const [jump, setJump] = useState('')

  useEffect(() => {
    document.body.classList.add('has-fixed-nav')
    return () => document.body.classList.remove('has-fixed-nav')
  }, [])

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
      <nav className="navbar navbar-expand-lg fixed-top">
        <div className="container-page">
          <Link className="navbar-brand" to="/"><i className="bi bi-kanban"></i> PM Tracker</Link>

          <button className="navbar-toggler btn btn-light btn-sm" type="button" data-bs-toggle="collapse" data-bs-target="#nav">
            <i className="bi bi-list"></i>
          </button>

          <div id="nav" className="collapse navbar-collapse">
            <ul className="navbar-nav me-3">
              <li className="nav-item dropdown">
                <span className="nav-link dropdown-toggle" role="button" data-bs-toggle="dropdown">
                  <i className="bi bi-diagram-3 me-1"></i>Projects
                </span>
                <ul className="dropdown-menu">
                  <li><NavLink className="dropdown-item" to="/">View Projects</NavLink></li>
                  <li><NavLink className="dropdown-item" to="/projects/new">New Project</NavLink></li>
                  <li><NavLink className="dropdown-item" to="/project-terms">Payment Terms</NavLink></li>
                </ul>
              </li>
              <li className="nav-item"><NavLink className="nav-link" to="/customers"><i className="bi bi-people me-1"></i>Customers</NavLink></li>
              <li className="nav-item"><NavLink className="nav-link" to="/config"><i className="bi bi-sliders me-1"></i>Config</NavLink></li>
              <li className="nav-item"><NavLink className="nav-link" to="/users"><i className="bi bi-shield-lock me-1"></i>Users</NavLink></li>
            </ul>

            <form className="ms-auto d-flex me-3" onSubmit={onJump}>
              <div className="input-icon">
                <i className="bi bi-search"></i>
                <input className="form-control" style={{width:360}} placeholder="Jump: terms 12 / payment terms / users"
                       value={jump} onChange={e=>setJump(e.target.value)} />
              </div>
            </form>

            <div className="dropdown">
              <button className="btn btn-sm btn-light dropdown-toggle" data-bs-toggle="dropdown">
                <i className="bi bi-person-circle me-1"></i> {user?.name || 'Account'}
              </button>
              <ul className="dropdown-menu dropdown-menu-end">
                <li className="dropdown-item text-muted" style={{fontSize:'.85rem'}}>{user?.email || ''}</li>
                <li><hr className="dropdown-divider" /></li>
                <li><a className="dropdown-item" href="#" onClick={doLogout}><i className="bi bi-box-arrow-right me-2"></i>Sign out</a></li>
              </ul>
            </div>
          </div>
        </div>
      </nav>

      <main className="container-page">
        <Outlet />
        <div className="mt-4 footer-copy">© 2025 PM Tracker. All rights reserved.</div>
      </main>
    </>
  )
}
JSX

########################################
# 3) Pagination: always Bootstrap Icons (no unicode)
########################################
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
      <div className="btn-group pagination">
        <button className="btn btn-sm btn-outline-secondary" disabled={!canPrev} onClick={()=>setPage(1)}>
          <i className="bi bi-chevron-double-left me-1"></i>First
        </button>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canPrev} onClick={()=>setPage(page-1)}>
          <i className="bi bi-chevron-left me-1"></i>Prev
        </button>
        <span className="btn btn-sm btn-light disabled">{page} / {pages}</span>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canNext} onClick={()=>setPage(page+1)}>
          Next<i className="bi bi-chevron-right ms-1"></i>
        </button>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canNext} onClick={()=>setPage(pages)}>
          Last<i className="bi bi-chevron-double-right ms-1"></i>
        </button>
      </div>
    </div>
  )
}
JSX

########################################
# 4) Login: split layout, no unicode icons, tidy copy
########################################
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
          <div className="mb-2">
            <span className="badge-pill"><i className="bi bi-lightning-charge"></i> Faster PM Ops</span>
            <span className="badge-pill"><i className="bi bi-shield-check"></i> Role-based Access</span>
          </div>
          <h1>Track projects, terms and cashflow in one place.</h1>
          <p>PM Tracker helps your team create projects with payment milestones, update term statuses quickly, and keep finance and delivery in sync.</p>
          <ul className="mt-3 text-muted">
            <li>Instant search across projects and customers</li>
            <li>Payment terms with validation and status updates</li>
            <li>PM assignments that show only what each PM owns</li>
          </ul>
        </div>

        <div className="login-card">
          <div className="login-panel">
            <div className="d-flex align-items-center mb-3">
              <div className="me-2 rounded-circle bg-primary d-flex align-items-center justify-content-center" style={{width:42,height:42}}>
                <i className="bi bi-kanban text-white"></i>
              </div>
              <div>
                <div className="fw-bold">PM Tracker</div>
                <div className="copy-muted small">Sign in to your workspace</div>
              </div>
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
              {error ? <div className="text-danger small mb-2">{error}</div> : <div className="form-text">Use your PM Tracker credentials</div>}
              <button className="btn btn-primary w-100 mt-2" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button>
            </form>
            <div className="mt-3 small copy-muted">
              By signing in you agree to our acceptable use and privacy terms.
            </div>
          </div>
        </div>
      </div>
      <div className="footer-copy">© 2025 PM Tracker. All rights reserved.</div>
    </>
  )
}
JSX

########################################
# Build and (re)serve
########################################
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &
echo "UI fixes applied. Refresh your browser (Ctrl/Cmd+Shift+R)."
