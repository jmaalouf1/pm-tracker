import { Outlet, Link } from "react-router-dom";

export default function Layout() {
  return (
    <div className="min-h-screen bg-gray-50 text-gray-900">
      <nav className="bg-blue-600 text-white">
        <div className="max-w-6xl mx-auto px-4 py-3 flex gap-4">
          <Link to="/">Projects</Link>
          <Link to="/projects/new">New Project</Link>
          <Link to="/customers">Customers</Link>
          <Link to="/users">Users</Link>
          <Link to="/login" className="ml-auto">Logout</Link>
        </div>
      </nav>
      <main className="max-w-6xl mx-auto p-4">
        <Outlet />
      </main>
    </div>
  );
}

