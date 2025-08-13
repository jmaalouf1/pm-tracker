set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

# --- Global CSS additions (navbar fix + login layout) ---
cat > "$SRC/app.css" <<'CSS'
:root{
  --brand:#1f6feb;
  --brand-700:#1a5fd1;
  --bg:#f6f8fb;
  --card:#ffffff;
  --text:#0f172a;
  --muted:#64748b;
  --radius:16px;
  --shadow:0 4px 18px rgba(16,24,40,.08);
}
html,body{background:var(--bg); color:var(--text); min-height:100%;}
/* Fixed navbar */
.navbar.fixed-top{box-shadow:var(--shadow); background:linear-gradient(90deg,var(--brand),var(--brand-700));}
.navbar .navbar-brand,.navbar .nav-link{color:#fff !important}
.navbar .navbar-brand{font-weight:800; letter-spacing:.3px}
.nav-spacer {height:64px;} /* pushes content below fixed navbar */

/* Generic containers */
.container-page{max-width:1200px; margin-inline:auto; padding:24px;}
.card{border:none; border-radius:var(--radius); background:var(--card); box-shadow:var(--shadow);}

/* Inputs */
.input-icon{position:relative}
.input-icon .bi{position:absolute; left:12px; top:50%; transform:translateY(-50%); opacity:.55}
.input-icon input{padding-left:38px}

/* Pagination look */
.table thead th{position:sticky; top:0; background:#fff; z-index:1}
.pagination .btn{min-width:72px}

/* ===== Login page ===== */
.login-wrap{
  min-height: calc(100vh - 64px); /* account for fixed navbar height */
  display:grid;
  grid-template-columns: 1fr;
}
@media (min-width: 992px){
  .login-wrap{ grid-template-columns: 1.1fr 0.9fr; }
}
.login-hero{
  display:none;
}
@media (min-width: 992px){
  .login-hero{
    display:block;
    background:
      radial-gradient(1000px 400px at -20% -10%, rgba(255,255,255,.35) 0%, rgba(255,255,255,0) 60%),
      linear-gradient(135deg, #e8f0ff 0%, #f7fbff 40%, #f3f7ff 100%);
    padding:48px;
    border-radius:24px;
    margin:24px;
    box-shadow:var(--shadow);
  }
}
.login-hero h1{font-weight:800; letter-spacing:.2px; margin-bottom:12px}
.login-hero p{color:var(--muted); font-size:1.05rem}
.login-hero .pill{
  display:inline-flex; align-items:center; gap:.5rem;
  padding:.5rem .8rem; border-radius:999px; background:#eef2ff; color:#334155; margin-right:.5rem; margin-bottom:.5rem
}

.login-card{
  padding:24px; display:flex; align-items:center; justify-content:center;
}
.login-panel{
  width:100%; max-width:440px; padding:28px; border-radius:20px;
  background:var(--card); box-shadow:var(--shadow);
}
.copy-muted{color:#94a3b8; font-size:.9rem}
.footer-copy{color:#94a3b8; font-size:.85rem; text-align:center; padding:16px 0 24px}
CSS

# --- Navbar (Layout.jsx) fixed at top + tidy jump box ---
cat > "$SRC/components/Layout.jsx" <<'JSX'
import React, { useState } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom'
import '../app.css'

export default function Layout() {
  const nav = useNavigate()
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

  return (
    <>
      <nav className="navbar navbar-expand-lg fixed-top">
        <div className="container-page py-2">
          <Link className="navbar-brand d-flex align-items-center" to="/">
            <i className="bi bi-kanban me-2"></i> PM Tracker
          </Link>
          <button className="navbar-toggler btn btn-light btn-sm" type="button" data-bs-toggle="collapse" data-bs-target="#nav">
            <i className="bi bi-list"></i>
          </button>
          <div id="nav" className="collapse navbar-collapse">
            <ul className="navbar-nav me-3 gap-1">
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
            <form className="ms-auto d-flex" onSubmit={onJump} style={{maxWidth:360, width:'100%'}}>
              <div className="input-icon w-100">
                <i className="bi bi-search"></i>
                <input className="form-control" placeholder="Jump: terms 12 / payment terms / users"
                       value={jump} onChange={e=>setJump(e.target.value)} />
              </div>
            </form>
          </div>
        </div>
      </nav>
      <div className="nav-spacer" />
      <main className="container-page">
        <Outlet />
        <div className="mt-4 footer-copy">© PM Tracker — All rights reserved.</div>
      </main>
    </>
  )
}
JSX

# --- Rich split login screen (right card, left hero, footer) ---
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
      <div className="nav-spacer" />
      <div className="login-wrap">
        {/* Left hero (only on large screens) */}
        <div className="login-hero">
          <span className="pill"><i className="bi bi-lightning-charge"></i> Faster PM Ops</span>
          <span className="pill"><i className="bi bi-shield-check"></i> Role-based Access</span>
          <h1>Track projects, terms & cashflow in one place.</h1>
          <p>PM Tracker helps your team create projects with payment milestones, update term statuses quickly, and keep finance and delivery in sync.</p>
          <ul className="mt-3 text-muted">
            <li>Instant search across projects and customers</li>
            <li>Payment terms with validation & status updates</li>
            <li>PM assignments — show only what each PM owns</li>
          </ul>
        </div>

        {/* Right login card */}
        <div className="login-card">
          <div className="login-panel">
            <div className="d-flex align-items-center mb-3">
              <div className="me-2 rounded-circle bg-primary d-flex align-items-center justify-content-center" style={{width:40,height:40}}>
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
              <div className="d-flex justify-content-between align-items-center mb-3">
                <div className="form-text">Use your PM Tracker credentials</div>
              </div>
              {error ? <div className="text-danger small mb-2">{error}</div> : null}
              <button className="btn btn-primary w-100" disabled={busy}>
                {busy ? 'Signing in…' : 'Sign in'}
              </button>
            </form>

            <div className="mt-3 small copy-muted">
              By signing in you agree to our acceptable use and privacy terms.
            </div>
          </div>
        </div>
      </div>
      <div className="footer-copy">© PM Tracker — {new Date().getFullYear()} — All rights reserved.</div>
    </>
  )
}
JSX

echo "==> Rebuild"
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "Done. Refresh the site."
