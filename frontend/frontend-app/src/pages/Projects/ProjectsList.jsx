import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";

export default function ProjectsList() {
  const { user, ready, api } = useAuth();
  const navigate = useNavigate();

  const [rows, setRows] = useState([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!ready) return;
    if (!user) { navigate("/login", { replace: true }); return; }

    let alive = true;
    setLoading(true);
    setError("");

    api.get("/projects")
      .then(({ data }) => { if (alive) setRows(Array.isArray(data) ? data : []); })
      .catch((err) => {
        if (err?.response?.status === 401) {
          localStorage.removeItem("token");
          navigate("/login", { replace: true });
          return;
        }
        setError(err?.response?.data?.message || err.message || "Internal server error");
      })
      .finally(() => alive && setLoading(false));

    return () => { alive = false; };
  }, [ready, user, api, navigate]);

  if (!ready) return null;
  if (loading) return <div className="p-4">Loading…</div>;
  if (error) return <div className="p-4 text-red-600">{error}</div>;

  return (
    <div className="p-4">
      <h1 className="text-xl font-semibold mb-3">Projects</h1>
      {rows.length === 0 ? "No results" : (
        <table className="min-w-full text-sm">
          <thead><tr>
            <th className="text-left p-2">Project ID</th>
            <th className="text-left p-2">Customer</th>
            <th className="text-left p-2">Status</th>
          </tr></thead>
          <tbody>
            {rows.map(r => (
              <tr key={r.id} className="border-t">
                <td className="p-2">{r.project_id}</td>
                <td className="p-2">{r.customer_name || r.customer_id}</td>
                <td className="p-2">{r.delivery_status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

