set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

mkdir -p "$SRC/components"

echo "==> Ensure Bootstrap Icons"
# Add Bootstrap Icons CDN to index.html if missing
if ! grep -q "bootstrap-icons" "$FRONT/index.html"; then
  sed -i 's#</head>#  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">\n</head>#' "$FRONT/index.html"
fi

echo "==> Global CSS theme tweaks"
cat > "$SRC/app.css" <<'CSS'
:root{
  --brand:#1f6feb;         /* stronger blue */
  --brand-700:#1a5fd1;
  --bg:#f7f9fc;
  --card:#ffffff;
  --text:#0f172a;
  --muted:#64748b;
  --radius:16px;
  --shadow:0 4px 16px rgba(16,24,40,.08);
}
html,body{background:var(--bg); color:var(--text);}
.navbar{box-shadow:var(--shadow); background:linear-gradient(90deg,var(--brand),var(--brand-700))}
.navbar .nav-link, .navbar .navbar-brand{color:#fff !important;}
.navbar .nav-link.active{font-weight:700; text-decoration:underline;}
.navbar .navbar-brand{font-weight:800; letter-spacing:.3px}
.container-page{max-width:1200px; margin-inline:auto; padding:24px; }
.card{border:none; border-radius:var(--radius); box-shadow:var(--shadow); background:var(--card);}
.table thead th{position:sticky; top:0; background:#fff; z-index:1}
.input-icon{position:relative}
.input-icon .bi{position:absolute; left:12px; top:50%; transform:translateY(-50%); opacity:.55}
.input-icon input{padding-left:38px}
.btn-icon .bi{margin-right:.4rem}
.btn-soft{background:#eef2ff; border-color:#eef2ff}
.badge-muted{background:#eef2ff; color:#334155}
.small-muted{color:var(--muted); font-size:.875rem}
.pagination .btn{min-width:72px}
.footer-muted{color:#94a3b8; font-size:.85rem}
CSS

echo "==> Reusable Pagination component"
cat > "$SRC/components/Pagination.jsx" <<'JSX'
import React from 'react'
export default function Pagination({page, pages, total, pageSize, setPage, setPageSize}){
  return (
    <div className="d-flex justify-content-between align-items-center mt-3">
      <div className="d-flex align-items-center gap-2">
        <span className="small-muted">Rows:</span>
        <select className="form-select form-select-sm" style={{width:'auto'}}
                value={pageSize} onChange={e=>setPageSize(Number(e.target.value))}>
          {[10,20,50,100].map(n => <option key={n} value={n}>{n}</option>)}
        </select>
        <span className="small-muted">Total: {total}</span>
      </div>
      <div className="btn-group pagination">
        <button className="btn btn-sm btn-outline-secondary" disabled={page<=1} onClick={()=>setPage(1)}>First</button>
        <button className="btn btn-sm btn-outline-secondary" disabled={page<=1} onClick={()=>setPage(page-1)}>Prev</button>
        <span className="btn btn-sm btn-light disabled">{page} / {pages}</span>
        <button className="btn btn-sm btn-outline-secondary" disabled={page>=pages} onClick={()=>setPage(page+1)}>Next</button>
        <button className="btn btn-sm btn-outline-secondary" disabled={page>=pages} onClick={()=>setPage(pages)}>Last</button>
      </div>
    </div>
  )
}
JSX

echo "==> Reusable Search input with icon"
cat > "$SRC/components/SearchBox.jsx" <<'JSX'
import React from 'react'
export default function SearchBox({value, onChange, placeholder="Search"}){
  return (
    <div className="input-icon w-100">
      <i className="bi bi-search"></i>
      <input className="form-control" value={value} onChange={e=>onChange(e.target.value)} placeholder={placeholder} />
    </div>
  )
}
JSX

echo "==> Polish Navbar (Layout)"
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
    if(!s) return
    if (s.startsWith('terms ')) { const id=s.replace(/\D+/g,''); if(id) return nav(`/projects/${id}/terms`) }
    if (s.includes('payment')) return nav('/project-terms')
    if (s.includes('users')) return nav('/users')
    if (s.includes('customers')) return nav('/customers')
    return nav('/')
  }

  return (
    <>
      <nav className="navbar navbar-expand-lg">
        <div className="container-page py-2">
          <Link className="navbar-brand d-flex align-items-center" to="/"><i className="bi bi-kanban me-2"></i>PM Tracker</Link>
          <button className="navbar-toggler btn btn-light btn-sm" type="button" data-bs-toggle="collapse" data-bs-target="#nav">
            <i className="bi bi-list"></i> Menu
          </button>
          <div id="nav" className="collapse navbar-collapse">
            <ul className="navbar-nav me-3 gap-1">
              <li className="nav-item dropdown">
                <span className="nav-link dropdown-toggle" role="button" data-bs-toggle="dropdown"><i className="bi bi-diagram-3 me-1"></i>Projects</span>
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
      <main className="container-page">
        <Outlet />
        <div className="mt-4 footer-muted">© PM Tracker</div>
      </main>
    </>
  )
}
JSX

echo "==> Refresh ProjectsList to use SearchBox + Pagination"
cat > "$SRC/pages/ProjectsList.jsx" <<'JSX'
import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { Link } from 'react-router-dom'
import SearchBox from '../components/SearchBox'
import Pagination from '../components/Pagination'

export default function ProjectsList() {
  const [rows, setRows] = useState([])
  const [q, setQ] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(20)
  const [total, setTotal] = useState(0)
  const [busy, setBusy] = useState(false)

  async function reload(p = page) {
    setBusy(true)
    const { data } = await api.get('/projects', { params: { q, page: p, pageSize } })
    setRows(data.data); setTotal(data.total); setPage(data.page)
    setBusy(false)
  }
  useEffect(() => { reload(1) }, [])
  useEffect(() => { const id = setTimeout(() => reload(1), 250); return () => clearTimeout(id) }, [q, pageSize])

  const pages = Math.max(1, Math.ceil(total / pageSize))

  return (
    <div className="card p-3">
      <div className="d-flex gap-3 align-items-center mb-3">
        <div className="flex-grow-1"><SearchBox value={q} onChange={setQ} placeholder="Search projects" /></div>
        <Link className="btn btn-primary btn-icon" to="/projects/new"><i className="bi bi-plus-lg"></i> New Project</Link>
      </div>
      <div className="table-responsive">
        <table className="table table-sm table-hover align-middle">
          <thead><tr>
            <th className="text-muted">ID</th>
            <th>Name</th>
            <th>Customer</th>
            <th>Segment</th>
            <th>Status</th>
            <th className="text-end">Remaining %</th>
            <th className="text-end">Backlog</th>
            <th>Actions</th>
          </tr></thead>
          <tbody>
            {rows.map(r=>(
              <tr key={r.id}>
                <td className="text-muted">{r.id}</td>
                <td>{r.name}</td>
                <td>{r.customer||''}</td>
                <td>{r.segment||''}</td>
                <td><span className="badge bg-light text-dark">{r.status||''}</span></td>
                <td className="text-end">{Number(r.remaining_percent||0).toFixed(2)}%</td>
                <td className="text-end">{Number(r.backlog_amount||0).toLocaleString(undefined,{minimumFractionDigits:2,maximumFractionDigits:2})}</td>
                <td><Link to={`/projects/${r.id}/terms`} className="btn btn-sm btn-outline-primary"><i className="bi bi-pencil-square me-1"></i>Manage Terms</Link></td>
              </tr>
            ))}
            {rows.length===0 && (
              <tr><td colSpan="8" className="text-center py-4 text-muted">{busy?'Loading…':'No projects found'}</td></tr>
            )}
          </tbody>
        </table>
      </div>
      <Pagination page={page} pages={pages} total={total} pageSize={pageSize}
                  setPage={(p)=>{setPage(p); reload(p)}} setPageSize={setPageSize} />
    </div>
  )
}
JSX

echo "==> (Optional) Make Customers & Users pages benefit from the same styles"
# Light touches if files exist: wrap main content in a card and add headings consistency
for P in Customers Users Config PaymentTerms ProjectTerms ProjectNew; do
  F="$SRC/pages/$P.jsx"
  if [ -f "$F" ]; then
    sed -i '1s/^/import "..\/app.css"\n/' "$F" || true
  fi
done

echo "==> Build & serve"
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "UI facelift applied."
