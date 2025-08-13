set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

# 0) Ensure Bootstrap Icons CDN is present
if ! grep -q 'bootstrap-icons' "$FRONT/index.html"; then
  sed -i 's#</head>#  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">\n</head>#' "$FRONT/index.html"
fi

# 1) Global CSS: fixed navbar + page offset, icon-safe footer, tidy inputs
cat > "$SRC/app.css" <<'CSS'
:root{
  --brand:#1f6feb; --brand-700:#1a5fd1;
  --bg:#f6f8fb; --card:#ffffff; --text:#0f172a; --muted:#64748b;
  --radius:16px; --shadow:0 4px 18px rgba(16,24,40,.08);
}
html,body{background:var(--bg); color:var(--text); min-height:100%;}
/* Fixed navbar with proper page offset */
.navbar.fixed-top{position:fixed; top:0; left:0; right:0; z-index:1030;
  background:linear-gradient(90deg,var(--brand),var(--brand-700)); box-shadow:var(--shadow);}
body.has-fixed-nav main{margin-top:76px;} /* push content below header */

.navbar .navbar-brand,.navbar .nav-link{color:#fff !important}
.navbar .navbar-brand{font-weight:800; letter-spacing:.3px}
.container-page{max-width:1200px; margin-inline:auto; padding:24px;}
.card{border:none; border-radius:var(--radius); background:var(--card); box-shadow:var(--shadow);}
.input-icon{position:relative}
.input-icon .bi{position:absolute; left:12px; top:50%; transform:translateY(-50%); opacity:.55}
.input-icon input{padding-left:38px}
.table thead th{position:sticky; top:0; background:#fff; z-index:1}
.pagination .btn{min-width:80px}
.footer-copy{color:#6b7280; font-size:.85rem; text-align:center; padding:16px 0 24px}
CSS

# 2) Layout.jsx: fixed-top, make body get the "has-fixed-nav" class, align Jump box to right with auto width, plain ASCII footer
cat > "$SRC/components/Layout.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom'
import '../app.css'

export default function Layout() {
  const nav = useNavigate()
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
            <form className="ms-auto d-flex" onSubmit={onJump}>
              <div className="input-icon">
                <i className="bi bi-search"></i>
                <input className="form-control" style={{width:360}} placeholder="Jump: terms 12 / payment terms / users"
                       value={jump} onChange={e=>setJump(e.target.value)} />
              </div>
            </form>
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

# 3) Pagination component: add Bootstrap Icons chevrons, disable states nicely
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
        <button className="btn btn-sm btn-outline-secondary" disabled={!canPrev} onClick={()=>setPage(1)}>
          <i className="bi bi-chevron-double-left me-1"></i> First
        </button>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canPrev} onClick={()=>setPage(page-1)}>
          <i className="bi bi-chevron-left me-1"></i> Prev
        </button>
        <span className="btn btn-sm btn-light disabled">{page} / {pages}</span>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canNext} onClick={()=>setPage(page+1)}>
          Next <i className="bi bi-chevron-right ms-1"></i>
        </button>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canNext} onClick={()=>setPage(pages)}>
          Last <i className="bi bi-chevron-double-right ms-1"></i>
        </button>
      </div>
    </div>
  )
}
JSX

# 4) Rebuild and restart static server
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "Nav fixed; icons updated; footer ascii; rebuild done. Refresh your browser."
