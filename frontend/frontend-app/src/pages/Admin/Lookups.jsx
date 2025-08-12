// src/pages/Admin/Lookups.jsx
import { useEffect, useState } from "react";
import { useAuth } from "../../context/AuthContext";

function toArray(x) {
  if (Array.isArray(x)) return x;
  if (Array.isArray(x?.rows)) return x.rows;  // if backend returns { rows: [...] }
  if (Array.isArray(x?.data)) return x.data;  // just in case
  return [];
}

export default function Lookups() {
  const { api } = useAuth();
  const [statuses, setStatuses] = useState([]); // [{id,label}]
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let alive = true;
    setLoading(true);
    setError("");

    api
      .get("/config/payment-statuses")
      .then(({ data }) => {
        if (!alive) return;
        setStatuses(toArray(data));
      })
      .catch((e) => {
        if (!alive) return;
        setError(e?.response?.data?.message || e.message || "Failed to load");
        setStatuses([]); // keep it an array to avoid .map errors
      })
      .finally(() => alive && setLoading(false));

    return () => {
      alive = false;
    };
  }, [api]);

  return (
    <div className="p-6">
      <h1 className="text-xl font-semibold mb-4">Payment Statuses</h1>

      {loading && <div>Loading…</div>}
      {!!error && (
        <div className="mb-3 rounded border border-red-200 bg-red-50 px-3 py-2 text-red-700">
          {error}
        </div>
      )}

      {statuses.length === 0 ? (
        <div className="text-gray-500">No statuses found.</div>
      ) : (
        <ul className="list-disc pl-6">
          {statuses.map((s) => (
            <li key={s.id ?? s.label}>{s.label ?? String(s)}</li>
          ))}
        </ul>
      )}
    </div>
  );
}

