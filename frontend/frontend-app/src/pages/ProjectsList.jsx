// src/pages/ProjectsList.jsx
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function ProjectsList() {
  const { api, signout } = useAuth();

  // data
  const [rows, setRows] = useState([]);
  const [customersById, setCustomersById] = useState({});

  // ui state
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");

  // search query (this fixes the “q is not defined” error)
  const [q, setQ] = useState("");

  // fetch projects + customers
  useEffect(() => {
    let alive = true;
    async function run() {
      setLoading(true);
      setErr("");
      try {
        const [pRes, cRes] = await Promise.all([
          api.get("/projects"),
          api.get("/customers"),
        ]);

        if (!alive) return;

        const customersMap = {};
        (cRes.data || []).forEach((c) => (customersMap[c.id] = c.name));
        setCustomersById(customersMap);

        setRows(Array.isArray(pRes.data) ? pRes.data : []);
      } catch (e) {
        // if token expired/invalid
        if (e?.response?.status === 401) {
          signout();
          setErr("Unauthorized. Please sign in again.");
        } else {
          setErr(e?.response?.data?.message || e.message || "Failed to load.");
        }
      } finally {
        if (alive) setLoading(false);
      }
    }
    run();
    return () => {
      alive = false;
    };
  }, [api, signout]);

  // filter by query
  const filtered = useMemo(() => {
    const term = q.trim().toLowerCase();
    if (!term) return rows;
    return rows.filter((r) =>
      [
        r.project_id,
        customersById[r.customer_id],
        r.description,
        r.currency,
        r.partner,
        r.delivery_status,
        r.year,
      ]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(term))
    );
  }, [rows, q, customersById]);

  // CSV export
  function exportCsv() {
    const headers = [
      "project_id",
      "customer",
      "description",
      "total_amount",
      "currency",
      "segments",
      "service_lines",
      "partner",
      "delivery_status",
      "year",
      "payment_terms",
      "assigned_resources",
      "created_by",
      "created_at",
      "updated_at",
    ];

    const toCell = (v) => {
      if (v == null) return "";
      if (typeof v === "object") v = JSON.stringify(v);
      // escape quotes
      const s = String(v).replace(/"/g, '""');
      return /[",\n]/.test(s) ? `"${s}"` : s;
    };

    const lines = [
      headers.join(","),
      ...filtered.map((r) =>
        [
          r.project_id,
          customersById[r.customer_id] || r.customer_id,
          r.description,
          r.total_amount,
          r.currency,
          r.segments,
          r.service_lines,
          r.partner,
          r.delivery_status,
          r.year,
          r.payment_terms,
          r.assigned_resources,
          r.created_by,
          r.created_at,
          r.updated_at,
        ]
          .map(toCell)
          .join(",")
      ),
    ];

    const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "projects.csv";
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="p-4 md:p-6">
      {/* Toolbar */}
      <div className="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <input
          className="w-full md:w-[520px] rounded-lg border border-blue-200 bg-white/70 px-4 py-2 outline-none focus:ring-2 focus:ring-blue-400"
          placeholder="Search by Project ID, Customer, Description, Currency, Partner…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />

        <div className="flex gap-3">
          <Link
            to="/projects/new"
            className="inline-flex items-center justify-center rounded-lg bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700"
          >
            New Project
          </Link>
          <button
            onClick={exportCsv}
            className="inline-flex items-center justify-center rounded-lg border border-blue-200 bg-white px-4 py-2 font-medium text-blue-700 hover:bg-blue-50"
          >
            Export CSV
          </button>
        </div>
      </div>

      {/* Error / Loading */}
      {err && (
        <div className="mb-4 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-red-700">
          {err}
        </div>
      )}
      {loading && (
        <div className="rounded-md border border-blue-200 bg-blue-50 px-4 py-3 text-blue-700">
          Loading projects…
        </div>
      )}

      {/* Table */}
      {!loading && !err && (
        <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white">
          <table className="min-w-full text-left text-sm">
            <thead className="bg-blue-50 text-blue-900">
              <tr>
                <th className="px-4 py-3">Project ID</th>
                <th className="px-4 py-3">Customer</th>
                <th className="px-4 py-3">Description</th>
                <th className="px-4 py-3">Amount</th>
                <th className="px-4 py-3">Currency</th>
                <th className="px-4 py-3">Partner</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Year</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td
                    colSpan={8}
                    className="px-4 py-6 text-center text-gray-500"
                  >
                    No results
                  </td>
                </tr>
              ) : (
                filtered.map((r) => (
                  <tr key={r.id} className="border-t hover:bg-gray-50/60">
                    <td className="px-4 py-3 font-medium text-gray-800">
                      {r.project_id}
                    </td>
                    <td className="px-4 py-3">
                      {customersById[r.customer_id] || r.customer_id}
                    </td>
                    <td className="px-4 py-3 text-gray-700 max-w-[420px]">
                      <span title={r.description || ""}>
                        {r.description || "—"}
                      </span>
                    </td>
                    <td className="px-4 py-3">{r.total_amount ?? "—"}</td>
                    <td className="px-4 py-3">{r.currency || "—"}</td>
                    <td className="px-4 py-3">{r.partner || "—"}</td>
                    <td className="px-4 py-3">{r.delivery_status || "—"}</td>
                    <td className="px-4 py-3">{r.year || "—"}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

