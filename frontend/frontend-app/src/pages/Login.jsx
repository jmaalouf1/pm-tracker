import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext.jsx";

export default function Login() {
  const [username, setU] = useState("");
  const [password, setP] = useState("");
  const [err, setErr] = useState("");
  const nav = useNavigate();
  const { signin } = useAuth();

  const submit = async (e) => {
    e.preventDefault();
    setErr("");
    try {
      await signin({ username, password }); // your context calls /auth/login
      nav("/");
    } catch (e) {
      setErr(e?.message || "Login failed");
    }
  };

  return (
    <div className="max-w-sm mx-auto mt-24 bg-white shadow p-6 rounded">
      <h1 className="text-xl font-semibold mb-4">Sign in</h1>
      {err && <div className="text-red-600 text-sm mb-2">{err}</div>}
      <form onSubmit={submit} className="space-y-3">
        <input className="w-full border rounded p-2" placeholder="Username"
               value={username} onChange={e=>setU(e.target.value)} />
        <input type="password" className="w-full border rounded p-2" placeholder="Password"
               value={password} onChange={e=>setP(e.target.value)} />
        <button className="w-full bg-blue-600 text-white rounded p-2">Sign in</button>
      </form>
    </div>
  );
}

