cat > src/components/Layout.jsx <<'JSX'
import React from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'

export default function Layout(){
  const navigate = useNavigate()
  const logout = () => { try{ localStorage.removeItem('token') }catch{}; navigate('/home',{replace:true}) }
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
          <button className="btn btn-light" onClick={logout}>Sign out</button>
        </div>
      </header>
      <main><Outlet/></main>
      <footer className="footer"><small>© {new Date().getFullYear()} PM Tracker</small></footer>
    </>
  )
}
JSX
