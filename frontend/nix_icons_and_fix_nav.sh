set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

# 1) Layout: plain brand text, no icons, tight navbar, jump box on right
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
          <Link className="navbar-brand" to="/">PM Tracker</Link>

          <button className="navbar-toggler btn btn-light btn-sm" type="button" data-bs-toggle="collapse" data-bs-target="#nav">
            Menu
          </button>

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
        <div className="mt-4 footer-copy">© 2025 PM Tracker. All rights reserved.</div>
      </main>
    </>
  )
}
JSX

# 2) Pagination: text-only buttons (no icon font required)
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

# 3) Global CSS: slimmer navbar; remove icon spacing rules
cat > "$SRC/app.css" <<'CSS'
:root{
  --brand:#1f6feb; --brand-700:#1a5fd1;
  --bg:#f7f9fc; --card:#ffffff; --text:#0f172a; --muted:#64748b;
  --radius:14px; --shadow:0 6px 18px rgba(16,24,40,.07);
}
html,body{background:var(--bg); color:var(--text); min-height:100%;}
.navbar.fixed-top{
  position:fixed; top:0; left:0; right:0; z-index:1030;
  background:linear-gradient(90deg,var(--brand),var(--brand-700));
  box-shadow:var(--shadow);
  padding-top:.25rem; padding-bottom:.25rem;
}
body.has-fixed-nav main{margin-top:58px;}
.navbar .navbar-brand,.navbar .nav-link{color:#fff !important}
.navbar .navbar-brand{font-weight:800; letter-spacing:.2px}
.navbar .nav-link{padding:.35rem .6rem; line-height:1.2}

.container-page{max-width:1200px; margin-inline:auto; padding:20px;}
.card{border:none; border-radius:var(--radius); background:var(--card); box-shadow:var(--shadow);}
.table thead th{position:sticky; top:0; background:#fff; z-index:1}

.footer-copy{color:#6b7280; font-size:.86rem; text-align:center; padding:16px 0 24px}
CSS

# 4) Remove any leftover <i className="..."> icons site-wide (safe)
#    This just deletes whole <i ...></i> tags from JSX files.
find "$SRC" -type f -name "*.jsx" -print0 | xargs -0 sed -i -E 's#<i className="[^"]*"></i>##g; s#<i className="[^"]*"></i>##g; s#<i className="[^"]*"></i>##g'

# 5) Also clean icon + text spacing like "  Manage Terms"
find "$SRC" -type f -name "*.jsx" -print0 | xargs -0 sed -i -E 's/  +/ /g'

# 6) Rebuild & serve
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "Icons removed and navbar tightened. Hard refresh your browser (Ctrl/Cmd+Shift+R)."
