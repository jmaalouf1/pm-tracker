// src/components/NavBar.jsx
import { Link, NavLink } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function NavBar() {
  const { user, signout } = useAuth();
  const link = "px-3 py-2 rounded-md text-sm font-medium";
  const active = "bg-blue-700 text-white";
  const inactive = "text-white/90 hover:bg-blue-700";

  return (
    <nav className="bg-blue-600 shadow">
      <div className="mx-auto max-w-7xl px-4">
        <div className="flex h-14 items-center justify-between">
          <Link to="/" className="text-white font-semibold">PM Tracker</Link>

          {user && (
            <div className="flex gap-1">
              <NavLink to="/projects" className={({isActive})=>`${link} ${isActive?active:inactive}`}>Projects</NavLink>
              <NavLink to="/projects/new" className={({isActive})=>`${link} ${isActive?active:inactive}`}>Add Project</NavLink>
              <NavLink to="/admin/lookups" className={({isActive})=>`${link} ${isActive?active:inactive}`}>Admin</NavLink>
            </div>
          )}

          <div className="flex items-center gap-3 text-white">
            {user ? (
              <>
                <span className="text-sm opacity-90">{user.username} ({user.role})</span>
                <button onClick={signout} className="rounded bg-blue-800 px-3 py-1 text-sm hover:bg-blue-900">Sign out</button>
              </>
            ) : (
              <NavLink to="/login" className="rounded bg-blue-800 px-3 py-1 text-sm hover:bg-blue-900">Sign in</NavLink>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}

