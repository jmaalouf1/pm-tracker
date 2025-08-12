import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import PaymentTermsEditor from "../../components/PaymentTermsEditor";

const DEFAULT_PARTNERS = ["eMcREY", "FIS", "CMA", "Datacard"];
const DEFAULT_DELIVERY = ["Hold", "Open", "Delivered", "Accepted"];
const DEFAULT_CURRENCIES = ["USD", "EUR", "GBP", "AED", "SAR"];

export default function NewProject() {
  const navigate = useNavigate();
  const { api } = useAuth();

  // ---------- form state ----------
  const [form, setForm] = useState({
    project_id: "",
    customer_id: null,
    customer_name: "", // for autocomplete UI only
    description: "",
    total_amount: "",
    currency: "USD",
    partner: "",
    delivery_status: "Open",
    year: new Date().getFullYear(),
  });

  const [terms, setTerms] = useState([]); // [{label, percent, amount, status_id, due_date, notes, sort_order}]

  // ---------- dropdown data (with safe fallbacks) ----------
  const [partners, setPartners] = useState(DEFAULT_PARTNERS);
  const [deliveryStatuses, setDeliveryStatuses] = useState(DEFAULT_DELIVERY);
  const [currencies, setCurrencies] = useState(DEFAULT_CURRENCIES);

  useEffect(() => {
    let alive = true;

    // Optional config endpoints; if they 404 we just keep defaults
    api.get("/config/partners")
      .then(({ data }) => { if (alive && Array.isArray(data) && data.length) setPartners(data.map(x => x.label || x)); })
      .catch(() => { /* ignore */ });

    api.get("/config/delivery-statuses")
      .then(({ data }) => { if (alive && Array.isArray(data) && data.length) setDeliveryStatuses(data.map(x => x.label || x)); })
      .catch(() => { /* ignore */ });

    api.get("/config/currencies")
      .then(({ data }) => { if (alive && Array.isArray(data) && data.length) setCurrencies(data.map(x => x.code || x.label || x)); })
      .catch(() => { /* ignore */ });

    return () => { alive = false; };
  }, [api]);

  // ---------- customer autocomplete ----------
  const [custQuery, setCustQuery] = useState("");
  const [custOptions, setCustOptions] = useState([]);
  const [showCust, setShowCust] = useState(false);
  const debounced = useDebounce(custQuery, 250);

  useEffect(() => {
    let alive = true;
    if (!debounced?.trim()) { setCustOptions([]); return; }
    api.get(`/customers?search=${encodeURIComponent(debounced)}&limit=10`)
      .then(({ data }) => { if (alive) setCustOptions(Array.isArray(data) ? data : []); })
      .catch(() => setCustOptions([]));
    return () => { alive = false; };
  }, [debounced, api]);

  function pickCustomer(c) {
    setForm(f => ({ ...f, customer_id: c.id, customer_name: c.name }));
    setShowCust(false);
  }

  // ---------- helpers ----------
  function update(name, value) {
    setForm(prev => ({ ...prev, [name]: value }));
  }

  const totalAmountNumber = useMemo(
    () => Number(form.total_amount || 0),
    [form.total_amount]
  );

  // ---------- submit ----------
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");

    if (!form.project_id?.trim()) return setError("Project ID is required.");
    if (!form.customer_id) return setError("Please choose a customer.");
    const amt = Number(form.total_amount);
    if (Number.isNaN(amt) || amt < 0) return setError("Total amount must be a valid number.");

    try {
      setSaving(true);

      const payload = {
        project_id: form.project_id.trim(),
        customer_id: form.customer_id,
        description: form.description?.trim() || null,
        total_amount: amt,
        currency: form.currency || null,
        partner: form.partner || null,
        delivery_status: form.delivery_status || null,
        year: Number(form.year) || null,
        // send the payment terms array (backend computes amounts too, but we include our amounts)
        terms: terms.map((t, i) => ({
          label: t.label?.trim() || `Term ${i + 1}`,
          percent: Number(t.percent) || 0,
          amount: Number(t.amount) || 0,
          status_id: t.status_id || null,
          due_date: t.due_date || null,
          notes: t.notes?.trim() || null,
          sort_order: Number(t.sort_order ?? i)
        }))
      };

      await api.post("/projects", payload);
      navigate("/projects");
    } catch (err) {
      setError(err?.response?.data?.message || err.message || "Failed to create project");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="mx-auto max-w-5xl px-4 py-6">
      <div className="mb-4">
        <h1 className="text-2xl font-semibold text-blue-900">New Project</h1>
        <p className="text-sm text-gray-500">Create a new project and define its payment terms.</p>
      </div>

      {error && (
        <div className="mb-4 rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Top grid */}
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="mb-1 block text-sm font-medium text-blue-900">Project ID</label>
            <input
              className="w-full rounded border border-blue-200 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              value={form.project_id}
              onChange={(e) => update("project_id", e.target.value)}
              placeholder="e.g. PRJ-2025-001"
            />
          </div>

          <div className="relative">
            <label className="mb-1 block text-sm font-medium text-blue-900">Customer</label>
            <input
              className="w-full rounded border border-blue-200 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              value={form.customer_name}
              onChange={(e) => {
                setCustQuery(e.target.value);
                update("customer_name", e.target.value);
                update("customer_id", null);
                setShowCust(true);
              }}
              onFocus={() => setShowCust(true)}
              placeholder="Type to search customer..."
              autoComplete="off"
            />
            {showCust && custOptions.length > 0 && (
              <div className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded border border-blue-200 bg-white shadow">
                {custOptions.map((c) => (
                  <div
                    key={c.id}
                    className="cursor-pointer px-3 py-2 hover:bg-blue-50"
                    onMouseDown={() => pickCustomer(c)}
                  >
                    <div className="text-sm font-medium text-blue-900">{c.name}</div>
                    {c.country && <div className="text-xs text-gray-500">{c.country}</div>}
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="md:col-span-2">
            <label className="mb-1 block text-sm font-medium text-blue-900">Description</label>
            <textarea
              className="h-24 w-full rounded border border-blue-200 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              value={form.description}
              onChange={(e) => update("description", e.target.value)}
            />
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-blue-900">Total Amount</label>
            <input
              type="number"
              step="0.01"
              className="w-full rounded border border-blue-200 px-3 py-2"
              value={form.total_amount}
              onChange={(e) => update("total_amount", e.target.value)}
              placeholder="0.00"
            />
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-blue-900">Currency</label>
            <select
              className="w-full rounded border border-blue-200 px-3 py-2"
              value={form.currency}
              onChange={(e) => update("currency", e.target.value)}
            >
              {currencies.map((c) => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-blue-900">Partner</label>
            <select
              className="w-full rounded border border-blue-200 px-3 py-2"
              value={form.partner}
              onChange={(e) => update("partner", e.target.value)}
            >
              <option value="">(none)</option>
              {partners.map((p) => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-blue-900">Delivery Status</label>
            <select
              className="w-full rounded border border-blue-200 px-3 py-2"
              value={form.delivery_status}
              onChange={(e) => update("delivery_status", e.target.value)}
            >
              {deliveryStatuses.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-blue-900">Year</label>
            <input
              type="number"
              min="2020"
              max="2035"
              className="w-full rounded border border-blue-200 px-3 py-2"
              value={form.year}
              onChange={(e) => update("year", e.target.value)}
            />
          </div>
        </div>

        {/* Payment Terms */}
        <PaymentTermsEditor
          totalAmount={totalAmountNumber}
          value={terms}
          onChange={setTerms}
        />

        {/* Actions */}
        <div className="flex items-center gap-3">
          <button
            type="submit"
            disabled={saving}
            className="rounded bg-blue-600 px-5 py-2.5 font-medium text-white hover:bg-blue-700 disabled:opacity-60"
          >
            {saving ? "Creating..." : "Create Project"}
          </button>
          <button
            type="button"
            className="rounded border border-blue-200 px-5 py-2.5 text-blue-700 hover:bg-blue-50"
            onClick={() => navigate("/projects")}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}

/* ---------- tiny debounce hook ---------- */
function useDebounce(value, delay=300) {
  const [v, setV] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setV(value), delay);
    return () => clearTimeout(t);
  }, [value, delay]);
  return v;
}

