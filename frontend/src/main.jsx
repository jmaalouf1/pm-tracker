// frontend/src/main.jsx
import React, { Suspense } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import './app.css'

import Layout from './components/Layout.jsx'
import RequireAuth from './components/RequireAuth.jsx'

// Pages
import Login from './pages/Login.jsx'
import Home from './pages/Home.jsx'
import ImportExcel from './pages/Import.jsx'
import ProjectsList from './pages/ProjectsList.jsx'
import ProjectForm from './pages/ProjectForm.jsx'
import PaymentTerms from './pages/PaymentTerms.jsx'
import Customers from './pages/Customers.jsx'
import Config from './pages/Config.jsx'
import Users from './pages/Users.jsx'

class ErrorBoundary extends React.Component {
  constructor(p){ super(p); this.state={hasError:false,error:null} }
  static getDerivedStateFromError(error){ return {hasError:true,error} }
  render(){ return this.state.hasError
    ? <div className="container-page py-4"><div className="alert alert-danger"><b>Something went wrong</b><pre className="small m-0">{String(this.state.error?.stack||this.state.error)}</pre></div></div>
    : this.props.children }
}

const App = () => (
  <BrowserRouter>
    <ErrorBoundary>
      <Suspense fallback={<div className="container-page py-5">Loading…</div>}>
        <Routes>
          {/* Public */}
          <Route path="/login" element={<Login />} />

          {/* Protected area */}
          <Route element={<RequireAuth><Layout /></RequireAuth>}>
            <Route path="/" element={<Navigate to="/home" replace />} />
            <Route path="/home" element={<Home />} />
            <Route path="/import" element={<ImportExcel />} />
            <Route path="/projects" element={<ProjectsList />} />
            <Route path="/projects/new" element={<ProjectForm />} />
            <Route path="/projects/:id/terms" element={<PaymentTerms />} />
            <Route path="/project-terms" element={<PaymentTerms />} />
            <Route path="/customers" element={<Customers />} />
            <Route path="/config" element={<Config />} />
            <Route path="/users" element={<Users />} />
            <Route path="*" element={<Navigate to="/home" replace />} />
          </Route>
        </Routes>
      </Suspense>
    </ErrorBoundary>
  </BrowserRouter>
)

createRoot(document.getElementById('root')).render(<App />)
