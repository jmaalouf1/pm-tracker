import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { Link } from 'react-router-dom'

export default function ProjectsList() {
  const [rows, setRows] = useState([])
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(false)

  async function load() {
    setLoading(true)
    const { data } = await api.get('/projects', { params: { search: query } })
    setRows(data.data)
    setLoading(false)
  }
  useEffect(() => { load() }, [])

  return (
    <div>
      <h2>Projects</h2>
      <div style={{ display:'flex', gap:8, marginBottom:12 }}>
        <input placeholder="Search..." value={query} onChange={e=>setQuery(e.target.value)} />
        <button onClick={load} disabled={loading}>Search</button>
        <Link className="primary" to="/projects/new">New Project</Link>
      </div>
      <table>
        <thead>
          <tr>
            <th>ID</th><th>Name</th><th>Customer</th><th>Segment</th><th>Service Line</th><th>Partner</th>
            <th>Status</th><th>Remaining %</th><th>Backlog</th><th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(r => (
            <tr key={r.id}>
              <td>{r.id}</td>
              <td>{r.name}</td>
              <td>{r.customer || ''}</td>
              <td>{r.segment || ''}</td>
              <td>{r.service_line || ''}</td>
              <td>{r.partner || ''}</td>
              <td>{r.status || ''}</td>
              <td>{Number(r.remaining_percent||0).toFixed(2)}%</td>
              <td>{Number(r.backlog_amount||0).toLocaleString(undefined,{minimumFractionDigits:2, maximumFractionDigits:2})}</td>
              <td><Link to={`/projects/${r.id}/terms`}>Manage Terms</Link></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
