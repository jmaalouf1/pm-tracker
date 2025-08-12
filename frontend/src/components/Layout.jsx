import React from 'react'
import { Link, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function Layout() {
  const { logout } = useAuth()
  const loc = useLocation()
  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <aside style={{ width: 260, borderRight: '1px solid #ddd', padding: 16 }}>
        <h2>PM Tracker</h2>
        <nav>
          <div style={{ fontWeight: 'bold', marginTop: 8 }}>Projects</div>
          <ul>
            <li><Link to="/">View Projects</Link></li>
            <li><Link to="/projects/new">New Project</Link></li>
            <li><Link to="/payment-terms">Payment Terms</Link></li>
          </ul>
          <div style={{ fontWeight: 'bold', marginTop: 12 }}>Configuration</div>
          <ul>
            <li><Link to="/config">Dropdowns & Statuses</Link></li>
          </ul>
        </nav>
        <button onClick={logout} style={{ marginTop: 16 }}>Logout</button>
      </aside>
      <main style={{ flex: 1, padding: 24 }}>
        <Outlet key={loc.key} />
      </main>
    </div>
  )
}
