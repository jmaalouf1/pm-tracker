// frontend/src/components/RequireAuth.jsx
import React from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { getToken } from '../lib/api'

export default function RequireAuth({ children }) {
  const token = getToken()
  const location = useLocation()
  if (!token) {
    return <Navigate to="/login" replace state={{ from: location.pathname + location.search }} />
  }
  return children
}
