import React, { useEffect, useState } from 'react'
import api from '../services/api'

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
      <div style={{ marginBottom: 12 }}>
        <input placeholder="Search..." value={query} onChange={e=>setQuery(e.target.value)} />
        <button onClick={load} disabled={loading}>Search</button>
      </div>
      <table border="1" cellPadding="6" cellSpacing="0" width="100%">
        <thead>
          <tr>
            <th>ID</th><th>Name</th><th>Customer</th><th>Segment</th><th>Service Line</th><th>Partner</th><th>Status</th><th>Invoice</th><th>PO</th><th>Backlog 2025</th>
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
              <td>{r.invoice_status || ''}</td>
              <td>{r.po_status || ''}</td>
              <td>{Number(r.backlog_2025 || 0).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
