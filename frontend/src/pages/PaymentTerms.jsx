import React, { useEffect, useState } from 'react'
import api from '../services/api'

export default function PaymentTerms() {
  const [filters, setFilters] = useState({ project_id:'', customer_id:'', status_id:'', q:'' })
  const [opts, setOpts] = useState({ projects: [], customers: [], statuses: [] })
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,statuses' } })
      setOpts(o => ({ ...o, customers: data.customers || [], statuses: (data.statuses || []).filter(s=>s.type==='term_status') }))
      // Lightweight projects list pulled from /projects for now
      const proj = await api.get('/projects', { params: { search: '' } })
      setOpts(o => ({ ...o, projects: proj.data.data || [] }))
    }
    load()
  }, [])

  async function search() {
    setLoading(true)
    const { data } = await api.get('/project-terms', { params: filters })
    setRows(data)
    setLoading(false)
  }

  async function updateStatus(id, status_id) {
    await api.patch(`/project-terms/${id}`, { status_id: status_id || null })
    await search()
  }

  return (
    <div>
      <h2 className="mb-3">Payment Terms</h2>
      <div className="card shadow-sm mb-3">
        <div className="card-body">
          <div className="row g-2 align-items-end">
            <div className="col-md-3">
              <label className="form-label">Project</label>
              <select className="form-select" value={filters.project_id} onChange={e=>setFilters(f=>({...f,project_id:e.target.value}))}>
                <option value="">Any</option>
                {opts.projects.map(p=> <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
            </div>
            <div className="col-md-3">
              <label className="form-label">Customer</label>
              <select className="form-select" value={filters.customer_id} onChange={e=>setFilters(f=>({...f,customer_id:e.target.value}))}>
                <option value="">Any</option>
                {opts.customers.map(c=> <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            <div className="col-md-3">
              <label className="form-label">Term Status</label>
              <select className="form-select" value={filters.status_id} onChange={e=>setFilters(f=>({...f,status_id:e.target.value}))}>
                <option value="">Any</option>
                {opts.statuses.map(s=> <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>
            <div className="col-md-3">
              <label className="form-label">Text</label>
              <input className="form-control" placeholder="Description contains…" value={filters.q} onChange={e=>setFilters(f=>({...f,q:e.target.value}))} />
            </div>
          </div>
          <div className="mt-3">
            <button className="btn btn-primary" onClick={search} disabled={loading}>{loading?'Searching…':'Search'}</button>
          </div>
        </div>
      </div>

      <div className="table-responsive shadow-sm">
        <table className="table table-sm table-striped align-middle">
          <thead><tr>
            <th>ID</th><th>Project</th><th>Customer</th><th className="text-end">%</th><th>Description</th><th>Status</th><th>Updated</th>
          </tr></thead>
          <tbody>
            {rows.map(r=>(
              <tr key={r.id}>
                <td>{r.id}</td>
                <td>{r.project_name}</td>
                <td>{r.customer_name||''}</td>
                <td className="text-end">{Number(r.percentage||0).toFixed(2)}</td>
                <td>{r.description}</td>
                <td style={{width:240}}>
                  <select className="form-select form-select-sm" value={r.status_id || ''} onChange={e=>updateStatus(r.id, e.target.value?Number(e.target.value):null)}>
                    <option value="">--</option>
                    {(opts.statuses||[]).map(s=> <option key={s.id} value={s.id}>{s.name}</option>)}
                  </select>
                </td>
                <td>{r.updated_at ? new Date(r.updated_at).toLocaleString() : ''}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
