import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function Login() {
  const [email, setEmail] = useState('admin@example.com')
  const [password, setPassword] = useState('Admin@12345')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const { login } = useAuth()
  const nav = useNavigate()
  async function submit(e) {
    e.preventDefault(); setBusy(true); setError('')
    try { await login(email, password); nav('/') }
    catch (e) { setError(e.message || 'Login failed') }
    finally { setBusy(false) }
  }
  return (
    <div className="d-flex justify-content-center align-items-center" style={{minHeight:'70vh'}}>
      <div className="card shadow-sm container-narrow w-100">
        <div className="card-body">
          <h4 className="card-title mb-3">Sign in</h4>
          <form onSubmit={submit}>
            <div className="mb-3">
              <label className="form-label">Email</label>
              <input className="form-control" type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
            </div>
            <div className="mb-3">
              <label className="form-label">Password</label>
              <input className="form-control" type="password" value={password} onChange={e=>setPassword(e.target.value)} required />
            </div>
            {error ? <div className="text-danger small mb-2">{error}</div> : null}
            <button className="btn btn-primary" disabled={busy}>{busy ? 'Signing in…' : 'Login'}</button>
          </form>
        </div>
      </div>
    </div>
  )
}
