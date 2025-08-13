// frontend/src/components/Layout.jsx
import React from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { getToken, setToken } from '../lib/api'

export default function Layout(){
  const navigate = useNavigate()
  const tok = getToken()
  const logout = () => { setToken(''); navigate('/login', { replace:true }) }

  return (
    <>
      <header className="nav-bar">
        <div className="nav-left">
          <NavLink to="/home" className="nav-item">Home</NavLink>
          <NavLink to="/projects" className="nav-item">Projects</NavLink>
          <NavLink to="/customers" className="nav-item">Customers</NavLink>
          <NavLink to="/config" className="nav-item">Config</NavLink>
          <NavLink to="/users" className="nav-item">Users</NavLink>
          <NavLink to="/import" className="nav-item">Upload</NavLink>
        </div>
        <div className="nav-center">
          <input className="nav-search" placeholder="Jump: home / import / users / customers" />
        </div>
        <div className="nav-right">
          {tok ? <button className="btn btn-light" onClick={logout}>Sign out</button> : null}
        </div>
      </header>
      <main><Outlet/></main>
      <footer className="footer">
        <small>© {new Date().getFullYear()} PM Tracker</small>
      </footer>
    </>
  )
}
