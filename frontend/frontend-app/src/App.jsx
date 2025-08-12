// src/App.jsx
import { Routes, Route, BrowserRouter } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import NavBar from "./components/NavBar";
import ProtectedRoute from "./components/ProtectedRoute";

import Login from "./pages/Login";
import Home from "./pages/Home";
import ProjectsList from "./pages/Projects/ProjectsList";
import NewProject from "./pages/Projects/NewProject";
import AdminLookups from "./pages/Admin/Lookups";

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <div className="min-h-screen bg-slate-50">
          <NavBar />
          <main className="mx-auto max-w-7xl p-4">
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route path="/" element={
                <ProtectedRoute><Home /></ProtectedRoute>
              }/>
              <Route path="/projects" element={
                <ProtectedRoute><ProjectsList /></ProtectedRoute>
              }/>
              <Route path="/projects/new" element={
                <ProtectedRoute roles={["super_admin","pm_admin","pm_user"]}>
                  <NewProject />
                </ProtectedRoute>
              }/>
              <Route path="/admin/lookups" element={
                <ProtectedRoute roles={["super_admin"]}>
                  <AdminLookups />
                </ProtectedRoute>
              }/>
            </Routes>
          </main>
        </div>
      </BrowserRouter>
    </AuthProvider>
  );
}

