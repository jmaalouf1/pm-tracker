import { useEffect, useMemo, useState } from "react";
import { useAuth } from "../context/AuthContext";

/**
 * Props:
 * - totalAmount: number
 * - value: array of terms [{label, percent, amount, status_id, due_date, notes, sort_order}]
 * - onChange: fn(newArray)
 */
export default function PaymentTermsEditor({ totalAmount = 0, value = [], onChange }) {
  const { api } = useAuth();

  // ---- SAFE defaults if config endpoint is missing / different shape ----
  const DEFAULT_STATUS_OPTS = useMemo(
    () => [
      { id: "planned", label: "Planned" },
      { id: "invoiced", label: "Invoiced" },
      { id: "paid", label: "Paid" },
      { id: "hold", label: "On Hold" },
    ],
    []
  );

  const [statusOptions, setStatusOptions] = useState(DEFAULT_STATUS_OPTS);
  const safeOptions = Array.isArray(statusOptions) ? statusOptions : DEFAULT_STATUS_OPTS;

  // try to fetch /config/payment-statuses (optional)
  useEffect(() => {
    let alive = true;
    api
      .get("/config/payment-statuses")
      .then(({ data }) => {
        if (!alive) return;
        if (!Array.isArray(data) || data.length === 0) return;

        // Normalize to [{id,label}]
        const normalized = data.map((item, idx) => {
          if (item && typeof item === "object") {
            const id =
              item.id ??
              item.value ??
              item.code ??
              item.key ??
              String(idx + 1);
            const label =
              item.label ?? item.name ?? item.title ?? String(id);
            return { id: String(id), label: String(label) };
          }
          // string primitive
          return { id: String(item), label: String(item) };
        });

        if (normalized.length) setStatusOptions(normalized);
      })
      .catch(() => {
        // keep defaults silently
      });
    return () => {
      alive = false;
    };
  }, [api]);

  // helpers
  const toNum = (v) => (v === "" || v == null ? 0 : Number(v));
  const fmt2 = (n) =>
    Number.isFinite(n) ? Math.round(n * 100) / 100 : 0;

  const remainingPercent = useMemo(() => {
    const used = (value || []).reduce(
      (sum, t) => sum + (Number(t.percent) || 0),
      0
    );
    return Math.max(0, Math.round((100 - used) * 100) / 100);
  }, [value]);

  function updateRow(idx, patch) {
    const next = [...(value || [])];
    next[idx] = { ...(next[idx] || {}), ...patch };
    onChange?.(next);
  }

  function removeRow(idx) {
    const next = [...(value || [])];
    next.splice(idx, 1);
    onChange?.(next);
  }

  function addRow() {
    const defaultStatusId = safeOptions[0]?.id ?? null;
    const percent = remainingPercent > 0 ? remainingPercent : 0;
    const amount = fmt2((toNum(totalAmount) * percent) / 100);
    const next = [
      ...(value || []),
      {
        label: `Milestone ${((value || []).length || 0) + 1}`,
        percent,
        amount,
        status_id: defaultStatusId,
        due_date: null,
        notes: "",
        sort_order: (value?.length || 0),
      },
    ];
    onChange?.(next);
  }

  // when percent changes -> recalc amount
  function onPercentChange(idx, newPercent) {
    const p = Math.max(0, Math.min(100, toNum(newPercent)));
    const amount = fmt2((toNum(totalAmount) * p) / 100);
    updateRow(idx, { percent: p, amount });
  }

  // when amount changes -> recalc percent
  function onAmountChange(idx, newAmount) {
    const amt = Math.max(0, toNum(newAmount));
    const p = toNum(totalAmount) > 0 ? fmt2((amt / toNum(totalAmount)) * 100) : 0;
    updateRow(idx, { amount: amt, percent: p });
  }

  return (
    <div className="rounded-lg border border-blue-200 bg-white">
      <div className="flex items-center justify-between border-b border-blue-100 px  -4 px-4 py-3">
        <div>
          <h2 className="text-lg font-semibold text-blue-900">Payment Terms</h2>
          <p className="text-xs text-gray-500">
            Remaining percent: <span className="font-medium">{remainingPercent}%</span> of 100%
          </p>
        </div>
        <button
          type="button"
          onClick={addRow}
          className="rounded bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          + Add term
        </button>
      </div>

      <div className="w-full overflow-x-auto">
        <table className="min-w-[800px] w-full table-auto text-sm">
          <thead>
            <tr className="bg-blue-50 text-blue-900">
              <th className="px-3 py-2 text-left">Label</th>
              <th className="px-3 py-2 text-right">Percent %</th>
              <th className="px-3 py-2 text-right">Amount</th>
              <th className="px-3 py-2 text-left">Status</th>
              <th className="px-3 py-2 text-left">Due Date</th>
              <th className="px-3 py-2 text-left">Notes</th>
              <th className="px-3 py-2 text-right">Order</th>
              <th className="px-3 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(Array.isArray(value) ? value : []).map((row, idx) => (
              <tr key={idx} className="border-t border-blue-100">
                {/* Label */}
                <td className="px-3 py-2 align-top">
                  <input
                    className="w-full rounded border border-blue-200 px-2 py-1 focus:outline-none focus:ring-2 focus:ring-blue-400"
                    value={row.label ?? ""}
                    onChange={(e) => updateRow(idx, { label: e.target.value })}
                    placeholder={`Milestone ${idx + 1}`}
                  />
                </td>

                {/* Percent */}
                <td className="px-3 py-2 align-top text-right">
                  <input
                    type="number"
                    step="0.01"
                    className="w-28 rounded border border-blue-200 px-2 py-1 text-right"
                    value={row.percent ?? 0}
                    onChange={(e) => onPercentChange(idx, e.target.value)}
                  />
                </td>

                {/* Amount */}
                <td className="px-3 py-2 align-top text-right">
                  <input
                    type="number"
                    step="0.01"
                    className="w-32 rounded border border-blue-200 px-2 py-1 text-right"
                    value={row.amount ?? 0}
                    onChange={(e) => onAmountChange(idx, e.target.value)}
                  />
                </td>

                {/* Status */}
                <td className="px-3 py-2 align-top">
                  <select
                    className="w-40 rounded border border-blue-200 px-2 py-1"
                    value={row.status_id ?? ""}
                    onChange={(e) => updateRow(idx, { status_id: e.target.value })}
                  >
                    {safeOptions.map((opt) => (
                      <option key={opt.id} value={opt.id}>
                        {opt.label}
                      </option>
                    ))}
                  </select>
                </td>

                {/* Due date */}
                <td className="px-3 py-2 align-top">
                  <input
                    type="date"
                    className="rounded border border-blue-200 px-2 py-1"
                    value={row.due_date ?? ""}
                    onChange={(e) => updateRow(idx, { due_date: e.target.value })}
                  />
                </td>

                {/* Notes */}
                <td className="px-3 py-2 align-top">
                  <input
                    className="w-64 rounded border border-blue-200 px-2 py-1"
                    value={row.notes ?? ""}
                    onChange={(e) => updateRow(idx, { notes: e.target.value })}
                    placeholder="Optional notes"
                  />
                </td>

                {/* Order */}
                <td className="px-3 py-2 align-top text-right">
                  <input
                    type="number"
                    className="w-20 rounded border border-blue-200 px-2 py-1 text-right"
                    value={row.sort_order ?? idx}
                    onChange={(e) => updateRow(idx, { sort_order: Number(e.target.value) })}
                  />
                </td>

                {/* Remove */}
                <td className="px-3 py-2 align-top">
                  <button
                    type="button"
                    onClick={() => removeRow(idx)}
                    className="rounded border border-red-200 px-2 py-1 text-red-700 hover:bg-red-50"
                  >
                    Remove
                  </button>
                </td>
              </tr>
            ))}

            {(!value || value.length === 0) && (
              <tr>
                <td colSpan={8} className="px-3 py-6 text-center text-gray-500">
                  No terms yet. Click <span className="font-medium text-blue-700">Add term</span> to start.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Summary footer */}
      <div className="flex flex-wrap items-center justify-end gap-4 border-t border-blue-100 px-4 py-3 text-sm">
        <div className="text-gray-600">
          Total project amount: <span className="font-medium text-blue-900">{fmt2(toNum(totalAmount)).toLocaleString()}</span>
        </div>
        <div className="text-gray-600">
          Sum of terms:{" "}
          <span className="font-medium text-blue-900">
            {fmt2(
              (Array.isArray(value) ? value : []).reduce(
                (s, r) => s + (Number(r.amount) || 0),
                0
              )
            ).toLocaleString()}
          </span>
        </div>
      </div>
    </div>
  );
}

