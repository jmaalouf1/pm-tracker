set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

# 1) CSS: compact brand chip + strict navbar height/line-height
awk 'BEGIN{done=0}
{print}
/^\:root/ && done==0{
  done=1
}
END{}' "$SRC/app.css" > "$SRC/app.css.tmp"

cat >> "$SRC/app.css.tmp" <<'CSS'

/* ---- Brand chip to prevent navbar from stretching ---- */
.navbar .navbar-brand{padding:0 !important; margin:0; display:flex; align-items:center; gap:.5rem; color:#fff !important}
.brand-chip{
  width:28px; height:28px; border-radius:8px;
  background:rgba(255,255,255,.18);
  display:flex; align-items:center; justify-content:center;
  line-height:1; /* keep icon from adding height */
}
.brand-chip .bi{font-size:16px; line-height:1}
.navbar.fixed-top{padding-top:.30rem; padding-bottom:.30rem} /* slimmer */
.navbar .nav-link{padding:.35rem .6rem; line-height:1.2}
CSS

mv "$SRC/app.css.tmp" "$SRC/app.css"

# 2) Layout: use the brand chip; keep jump box right-aligned
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
          <Link className="navbar-brand" to="/">
            <span className="brand-chip"><i className="bi bi-kanban"></i></span>
            <span>PM Tracker</span>
          </Link>

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

# 3) Rebuild & restart static server
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "Brand icon compacted and navbar height fixed. Hard refresh the browser."
