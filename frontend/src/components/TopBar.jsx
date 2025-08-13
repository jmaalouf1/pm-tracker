import React, { useState } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import { Home, FolderGit2, Users, Settings, Shield, Upload } from 'lucide-react'
import SearchInput from './SearchInput'

export default function TopBar({ user, onLogout }) {
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
    if (s.includes('import')) return nav('/import')
    if (s.includes('home')) return nav('/home')
    return nav('/')
  }

  return (
    <nav className="topbar">
      <div className="topbar-row container-page">
        {/* LEFT: menus (now includes Home) */}
        <div className="topbar-left">
          <NavLink className="nav-link text-white" to="/home"><Home size={14} className="me-1" /> Home</NavLink>
          <div className="dropdown">
            <button className="btn btn-sm btn-outline-light dropdown-toggle" data-bs-toggle="dropdown">
              <FolderGit2 size={16} className="me-1" /> Projects
            </button>
            <ul className="dropdown-menu">
              <li><NavLink className="dropdown-item" to="/">View Projects</NavLink></li>
              <li><NavLink className="dropdown-item" to="/projects/new">New Project</NavLink></li>
              <li><NavLink className="dropdown-item" to="/project-terms">Payment Terms</NavLink></li>
            </ul>
          </div>
          <NavLink className="nav-link text-white" to="/customers"><Users size={14} className="me-1" /> Customers</NavLink>
          <NavLink className="nav-link text-white" to="/config"><Settings size={14} className="me-1" /> Config</NavLink>
          <NavLink className="nav-link text-white" to="/users"><Shield size={14} className="me-1" /> Users</NavLink>
          <NavLink className="nav-link text-white" to="/import"><Upload size={14} className="me-1" /> Import</NavLink>
        </div>

        {/* CENTER: search */}
        <div className="topbar-center">
          <form onSubmit={onJump} style={{width:'100%'}}>
            <SearchInput value={jump} onChange={setJump} placeholder="Jump: home / terms 12 / payment terms / import / users" />
          </form>
        </div>

        {/* RIGHT: account */}
        <div className="topbar-right">
          <div className="dropdown">
            <button className="btn btn-sm btn-light dropdown-toggle" data-bs-toggle="dropdown">
              {user?.name || 'Account'}
            </button>
            <ul className="dropdown-menu dropdown-menu-end">
              {user?.email ? <li className="dropdown-item text-muted" style={{fontSize:'.85rem'}}>{user.email}</li> : null}
              <li><hr className="dropdown-divider" /></li>
              <li><a className="dropdown-item" href="#" onClick={onLogout}>Sign out</a></li>
            </ul>
          </div>
        </div>
      </div>
    </nav>
  )
}
