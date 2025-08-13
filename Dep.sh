cat > ~/projects/frontend/fix_nav_and_question_mark.sh <<'SH'
set -euo pipefail
FRONT=~/projects/frontend
SRC="$FRONT/src"

###############################################
# 1) Shrink navbar + 3-zone layout (left/center/right)
###############################################
# CSS: smaller header + left/center/right flex rows, centered search
cat > "$SRC/app.css" <<'CSS'
:root{
  --brand:#1f6feb; --brand-700:#1a5fd1;
  --bg:#f7f9fc; --card:#ffffff; --text:#0f172a; --muted:#64748b;
  --radius:12px; --shadow:0 4px 14px rgba(16,24,40,.08);
}
html,body{background:var(--bg); color:var(--text); min-height:100%}

/* Slim, non-fixed navbar */
.navbar{
  background:linear-gradient(90deg,var(--brand),var(--brand-700));
  box-shadow:var(--shadow);
  padding:.35rem 0;         /* <— thinner */
}
.navbar .nav-link{color:#fff !important; padding:.35rem .6rem; line-height:1.2}
.navbar .dropdown-menu{font-size:.95rem}
.container-page{max-width:1200px; margin-inline:auto; padding:20px;}
/* 3-zone header */
.nav-row{display:flex; align-items:center; gap:12px; width:100%}
.nav-left{display:flex; align-items:center; gap:8px}
.nav-center{flex:1; display:flex; justify-content:center}
.nav-center .form-control{max-width:600px; min-width:320px}
.nav-right{display:flex; align-items:center; gap:8px}

.card{border:none; border-radius:var(--radius); background:var(--card); box-shadow:var(--shadow)}
.table thead th{position:sticky; top:0; background:#fff; z-index:1}
.footer-copy{color:#6b7280; font-size:.86rem; text-align:center; padding:16px 0 24px}
CSS

# Layout.jsx: left menus, center search, right account; no brand text
cat > "$SRC/components/Layout.jsx" <<'JSX'
import React, { useState } from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
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
  async function doLogout(e){ e.preventDefault(); try { await logout() } finally { nav('/login',{replace:true}) } }

  return (
    <>
      <nav className="navbar">
        <div className="container-page">
          <div className="nav-row">
            {/* LEFT: menus */}
            <div className="nav-left">
              <div className="dropdown">
                <button className="btn btn-sm btn-outline-light dropdown-toggle" data-bs-toggle="dropdown">Projects</button>
                <ul className="dropdown-menu">
                  <li><NavLink className="dropdown-item" to="/">View Projects</NavLink></li>
                  <li><NavLink className="dropdown-item" to="/projects/new">New Project</NavLink></li>
                  <li><NavLink className="dropdown-item" to="/project-terms">Payment Terms</NavLink></li>
                </ul>
              </div>
              <NavLink className="nav-link" to="/customers">Customers</NavLink>
              <NavLink className="nav-link" to="/config">Config</NavLink>
              <NavLink className="nav-link" to="/users">Users</NavLink>
            </div>

            {/* CENTER: search */}
            <div className="nav-center">
              <form onSubmit={onJump} style={{width:'100%'}}>
                <input
                  className="form-control"
                  placeholder="Jump: terms 12 / payment terms / users"
                  value={jump}
                  onChange={e=>setJump(e.target.value)}
                />
              </form>
            </div>

            {/* RIGHT: account */}
            <div className="nav-right">
              <div className="dropdown">
                <button className="btn btn-sm btn-light dropdown-toggle" data-bs-toggle="dropdown">
                  {user?.name || 'Account'}
                </button>
                <ul className="dropdown-menu dropdown-menu-end">
                  {user?.email ? <li className="dropdown-item text-muted" style={{fontSize:'.85rem'}}>{user.email}</li> : null}
                  <li><hr className="dropdown-divider" /></li>
                  <li><a className="dropdown-item" href="#" onClick={doLogout}>Sign out</a></li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </nav>

      <main className="container-page">
        <Outlet />
        <div className="mt-4 footer-copy">(c) 2025 All rights reserved.</div>
      </main>
    </>
  )
}
JSX

###############################################
# 2) Remove the stray “ ” in Payment Terms filter
###############################################
# Normalize any non-ASCII after "Description contains" in placeholders/labels
# (forces it to exactly "Description contains")
grep -RIl "Description contains" "$SRC" | xargs -r sed -i -E 's/(Description contains)[^"]*/\1/g'

# Also sweep common unicode punctuation to ASCII across src (safe)
find "$SRC" -type f -name "*.*" -print0 | xargs -0 perl -i -pe '
  s/\x{2026}/.../g;          # …
  s/[\x{2013}\x{2014}]/-/g;  # – —
  s/[\x{2018}\x{2019}]/'\''/g;# ‘ ’
  s/[\x{201C}\x{201D}]/"/g;   # “ ”
  s/\x{00A0}/ /g;             # NBSP
'

###############################################
# 3) Rebuild and serve
###############################################
cd "$FRONT"
npm run build
pkill -f "serve -s dist" 2>/dev/null || true
npx serve -s dist -l 5173 >/dev/null 2>&1 &

echo "Navbar slim & aligned (left menus, center search, right account). Question mark cleared. Hard refresh the browser."
SH

bash ~/projects/frontend/fix_nav_and_question_mark.sh
