import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function Login() {
  const [email, setEmail] = useState('admin@example.com')
  const [password, setPassword] = useState('Admin@12345')
  const { login } = useAuth()
  const nav = useNavigate()
  async function submit(e) {
    e.preventDefault()
    await login(email, password)
    nav('/')
  }
  return (
    <form onSubmit={submit} style={{ maxWidth: 360, margin: '10vh auto' }}>
      <h2>Sign in</h2>
      <div>
        <label>Email</label>
        <input value={email} onChange={e=>setEmail(e.target.value)} />
      </div>
      <div>
        <label>Password</label>
        <input type="password" value={password} onChange={e=>setPassword(e.target.value)} />
      </div>
      <button type="submit">Login</button>
    </form>
  )
}
