import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Layout from './components/Layout'
import Login from './pages/Login'
import ProjectsList from './pages/ProjectsList'
import ProjectNew from './pages/ProjectNew'
import ProjectTerms from './pages/ProjectTerms'
import PaymentTerms from './pages/PaymentTerms'
import Customers from './pages/Customers'
import Config from './pages/Config'
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
          <Route path="project-terms" element={<PaymentTerms />} />
          <Route path="customers" element={<Customers />} />
          <Route path="config" element={<Config />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </AuthProvider>
)
