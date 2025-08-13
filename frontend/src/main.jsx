import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Layout from './components/Layout'
import Login from './pages/Login'
import ProjectsList from './pages/ProjectsList'
import ProjectNew from './pages/ProjectNew'
import ProjectTerms from './pages/ProjectTerms'
import PaymentTerms from './pages/PaymentTerms' // legacy standalone
import Config from './pages/Config'
import Customers from './pages/Customers'
import './app.css'

function Protected({ children }) {
  const { user } = useAuth()
  return user ? children : <Navigate to="/login" replace />
}

createRoot(document.getElementById('root')).render(
  <AuthProvider>
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<Protected><Layout /></Protected>}>
          <Route index element={<ProjectsList />} />
          <Route path="projects/new" element={<ProjectNew />} />
          <Route path="projects/:id/terms" element={<ProjectTerms />} />
          <Route path="payment-terms" element={<PaymentTerms />} />
          <Route path="config" element={<Config />} />
          <Route path="customers" element={<Customers />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </AuthProvider>
)
