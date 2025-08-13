import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { Link } from 'react-router-dom'

export default function ProjectsList() {
  const [rows, setRows] = useState([])
  const [q, setQ] = useState('')
  const [busy, setBusy] = useState(false)
  async function load(){ setBusy(true); const {data}=await api.get('/projects',{params:{search:q}}); setRows(data.data); setBusy(false) }
  useEffect(()=>{ load() },[])
  return (
    <>
      <div className="d-flex gap-2 mb-3">
        <input className="form-control" placeholder="Search projects…" value={q} onChange={e=>setQ(e.target.value)} />
        <button className="btn btn-outline-secondary" onClick={load} disabled={busy}>Search</button>
        <Link className="btn btn-primary" to="/projects/new">New Project</Link>
      </div>
      <div className="table-responsive shadow-sm">
        <table className="table table-sm table-striped align-middle">
          <thead><tr>
            <th>ID</th><th>Name</th><th>Customer</th><th>Segment</th><th>Status</th>
            <th className="text-end">Remaining %</th><th className="text-end">Backlog</th><th>Actions</th>
          </tr></thead>
          <tbody>
            {rows.map(r=>(
              <tr key={r.id}>
                <td>{r.id}</td>
                <td>{r.name}</td>
                <td>{r.customer||''}</td>
                <td>{r.segment||''}</td>
                <td>{r.status||''}</td>
                <td className="text-end">{Number(r.remaining_percent||0).toFixed(2)}%</td>
                <td className="text-end">{Number(r.backlog_amount||0).toLocaleString(undefined,{minimumFractionDigits:2,maximumFractionDigits:2})}</td>
                <td><Link to={`/projects/${r.id}/terms`} className="btn btn-sm btn-outline-primary">Manage Terms</Link></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  )
}
