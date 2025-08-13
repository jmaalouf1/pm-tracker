import React, { createContext, useContext, useState } from 'react'
import api from '../services/api'
const Ctx = createContext(null)
export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  async function login(email, password) {
    const { data } = await api.post('/auth/login', { email, password })
    localStorage.setItem('accessToken', data.accessToken)
    localStorage.setItem('refreshToken', data.refreshToken)
    setUser(data.user)
  }
  function logout() {
    const rt = localStorage.getItem('refreshToken')
    api.post('/auth/logout', { refreshToken: rt }).catch(()=>{})
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    setUser(null)
  }
  return <Ctx.Provider value={{ user, login, logout }}>{children}</Ctx.Provider>
}
export const useAuth = () => useContext(Ctx)
