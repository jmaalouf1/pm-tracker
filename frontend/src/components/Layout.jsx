import React, { useState } from 'react'
import { Link, Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './layout.css'

export default function Layout() {
  const { logout } = useAuth()
  const nav = useNavigate()
  const [q, setQ] = useState('')

  function go(e) {
    e.preventDefault()
    const s = q.trim().toLowerCase()
    if (!s) return
    if (s.includes('new project')) return nav('/projects/new')
    if (s.includes('projects')) return nav('/')
    if (s.startsWith('terms')) {
      const id = s.replace(/\D+/g, ''); if (id) return nav(`/projects/${id}/terms`)
    }
    if (s.includes('customers') || s.includes('customer')) return nav('/customers')
    if (s.includes('config') || s.includes('status') || s.includes('segment')) return nav('/config')
    return nav('/')
  }

  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand"><Link to="/">PM Tracker</Link></div>
        <nav className="menu">
          <div className="dropdown">
            <span>Projects ▾</span>
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
        <button className="logout" onClick={logout}>Logout</button>
      </header>
      <main className="content">
        <Outlet />
      </main>
    </div>
  )
}
