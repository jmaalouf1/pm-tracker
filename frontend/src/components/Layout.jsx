import React, { useState } from 'react'
import { Link, Outlet, useNavigate } from 'react-router-dom'
import '../app.css'

export default function Layout() {
  const nav = useNavigate()
  const [q, setQ] = useState('')
  function onSearch(e) {
    e.preventDefault()
    const s = q.trim().toLowerCase()
    if (!s) return
    if (s.includes('new project')) return nav('/projects/new')
    if (s.startsWith('terms')) { const id = s.replace(/\D+/g, ''); if (id) return nav(`/projects/${id}/terms`) }
    if (s.includes('customers')) return nav('/customers')
    if (s.includes('config')) return nav('/config')
    if (s.includes('payment terms') || s.includes('terms admin')) return nav('/project-terms')
    return nav('/')
  }
  return (
    <>
      <nav className="navbar navbar-expand-lg navbar-dark bg-primary">
        <div className="container-fluid">
          <Link className="navbar-brand" to="/">PM Tracker</Link>
          {/* Use clean text toggler to avoid the "?" icon */}
          <button className="navbar-toggler text-white border-0" type="button" data-bs-toggle="collapse" data-bs-target="#nav">Menu</button>
          <div id="nav" className="collapse navbar-collapse">
            <ul className="navbar-nav me-3">
              <li className="nav-item dropdown">
                <span className="nav-link dropdown-toggle" role="button" data-bs-toggle="dropdown">Projects</span>
                <ul className="dropdown-menu">
                  <li><Link className="dropdown-item" to="/">View Projects</Link></li>
                  <li><Link className="dropdown-item" to="/projects/new">New Project</Link></li>
                  <li><Link className="dropdown-item" to="/project-terms">Payment Terms</Link></li>
                </ul>
              </li>
              <li className="nav-item"><Link className="nav-link" to="/customers">Customers</Link></li>
              <li className="nav-item"><Link className="nav-link" to="/config">Config</Link></li>
            </ul>
            <form className="d-flex ms-auto" onSubmit={onSearch}>
              <input className="form-control" placeholder="Jump: terms 12 / payment terms / customers" value={q} onChange={e=>setQ(e.target.value)} />
            </form>
          </div>
        </div>
      </nav>
      <main className="container py-4">
        <Outlet />
      </main>
    </>
  )
}
