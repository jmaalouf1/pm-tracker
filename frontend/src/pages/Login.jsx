// frontend/src/pages/Login.jsx
import React, { useState } from 'react'
import { useNavigate, useLocation, Link } from 'react-router-dom'
import { setToken, apiFetch } from '../lib/api'

export default function Login() {
  const [email, setEmail] = useState('admin@example.com')
  const [password, setPassword] = useState('password')
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState(null)
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state && location.state.from) || '/home'

async function onSubmit(e) {
  e.preventDefault()
  setBusy(true); setErr(null)
  try {
    const res = await apiFetch('/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    })
    const out = await res.json().catch(() => ({}))
    const tok = out.token || out.accessToken || out.access_token
    if (!res.ok || !tok) throw new Error(out?.message || 'Login failed')
    setToken(tok)
    navigate(from, { replace: true })
  } catch (e) { setErr(e) } finally { setBusy(false) }
}

  return (
    <div className="container-page py-5" style={{maxWidth: 520}}>
      <h2 className="mb-3">Sign in</h2>
      <p className="text-muted">Use your PM Tracker credentials.</p>
      <form onSubmit={onSubmit} className="card p-3">
        <label className="form-label">Email</label>
        <input className="form-control mb-2" value={email} onChange={e=>setEmail(e.target.value)} />
        <label className="form-label">Password</label>
        <input type="password" className="form-control mb-3" value={password} onChange={e=>setPassword(e.target.value)} />
        {err && <div className="alert alert-danger">{String(err.message || err)}</div>}
        <button className="btn btn-primary" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button>
      </form>
      <div className="mt-3">
        <Link to="/home">Back to home</Link>
      </div>
    </div>
  )
}
