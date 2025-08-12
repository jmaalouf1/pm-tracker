import { useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useNavigate } from "react-router-dom";

export default function Login() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState("");
  const { login, loading } = useAuth();
  const navigate = useNavigate();

  const submit = async (e) => {
    e.preventDefault();
    setErr("");
    try {
      await login(username, password);
      navigate("/");
    } catch (e) {
      setErr(e?.response?.data?.message || "Login failed");
    }
  };

  return (
    <div className="min-h-screen grid place-items-center px-4">
      <div className="w-full max-w-sm bg-white rounded-xl shadow-sm border p-6">
        <h1 className="text-xl font-semibold mb-1">Welcome back</h1>
        <p className="text-sm text-slate-500 mb-5">Sign in to continue</p>

        {err && <div className="mb-4 rounded-md bg-red-50 text-red-700 text-sm p-3 border border-red-100">{err}</div>}

        <form onSubmit={submit} className="space-y-4">
          <div>
            <label className="block text-sm mb-1">Username</label>
            <input
              className="w-full rounded-md border px-3 py-2 outline-none focus:ring-2 focus:ring-slate-900/10"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              autoComplete="username"
              required
            />
          </div>
          <div>
            <label className="block text-sm mb-1">Password</label>
            <input
              type="password"
              className="w-full rounded-md border px-3 py-2 outline-none focus:ring-2 focus:ring-slate-900/10"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              required
            />
          </div>
          <button
            disabled={loading}
            className="w-full rounded-md bg-slate-900 text-white py-2 hover:bg-black transition disabled:opacity-50"
          >
            {loading ? "Signing in…" : "Sign in"}
          </button>
        </form>
      </div>
    </div>
  );
}

