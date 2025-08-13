import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import '../app.css'

export default function Login() {
  const [email, setEmail] = useState('admin@example.com')
  const [password, setPassword] = useState('Admin@12345')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const { login, user } = useAuth()
  const nav = useNavigate()
  useEffect(()=>{ if(user) nav('/') },[user])

  async function submit(e) {
    e.preventDefault(); setBusy(true); setError('')
    try { await login(email, password); nav('/') }
    catch (e) { setError(e.message || 'Login failed') }
    finally { setBusy(false) }
  }

  return (
    <>
      <div className="login-wrap">
        <div className="login-hero">
          <h1>Track projects, terms and cashflow in one place</h1>
          <p>Create projects with milestones, update term statuses quickly, and keep finance and delivery in sync.</p>
          <ul className="mt-3" style={{color:'#5b677a'}}>
            <li>Instant search across projects and customers</li>
            <li>Payment terms with validation and status updates</li>
            <li>PM assignments that show only what each PM owns</li>
          </ul>
        </div>

        <div className="d-flex justify-content-center">
          <div className="login-panel">
            <div className="mb-3">
              <div className="fw-bold">PM Tracker</div>
              <div className="copy-muted small">Sign in to your workspace</div>
            </div>

            <form onSubmit={submit}>
              <div className="mb-3">
                <label className="form-label fw-bold">Email</label>
                <input className="form-control" type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
              </div>
              <div className="mb-2">
                <label className="form-label fw-bold">Password</label>
                <input className="form-control" type="password" value={password} onChange={e=>setPassword(e.target.value)} required />
              </div>
              {error ? <div className="text-danger small mb-2">{error}</div> : <div className="form-text">Use your PM Tracker credentials.</div>}
              <button className="btn btn-primary w-100 mt-2" disabled={busy}>{busy ? 'Signing in...' : 'Sign in'}</button>
            </form>
          </div>
        </div>
      </div>

      <div className="footer-copy">(c) 2025 PM Tracker. All rights reserved.</div>
    </>
  )
}
