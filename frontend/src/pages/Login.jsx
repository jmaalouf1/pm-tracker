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
    <form onSubmit={submit} className="container">
      <h2>Sign in</h2>
      <label>Email</label>
      <input autoFocus type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
      <label>Password</label>
      <input type="password" value={password} onChange={e=>setPassword(e.target.value)} required />
      {error ? <small className="error">{error}</small> : null}
      <button type="submit" disabled={busy}>{busy ? 'Signing in…' : 'Login'}</button>
    </form>
  )
}
