import React from 'react'
import { Outlet } from 'react-router-dom'
import '../app.css'
import TopBar from './TopBar'
import { useAuth } from '../context/AuthContext'

export default function Layout() {
  const { user, logout } = useAuth()
  async function onLogout(e){ e.preventDefault(); try { await logout() } finally { window.location.href='/login' } }
  return (
    <>
      <TopBar user={user} onLogout={onLogout} />
      <main className="container-page">
        <Outlet />
        <div className="mt-4 footer-copy">(c) 2025 All rights reserved.</div>
      </main>
    </>
  )
}
