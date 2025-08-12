import React, { useEffect, useState } from 'react'
import api from '../services/api'

function Editor({ title, type, rows, setRows, extra }) {
  const [name, setName] = useState('')
  const [statusType, setStatusType] = useState('project_status')
  const [isActive, setIsActive] = useState(true)
  async function add() {
    if (type === 'statuses')
      await api.post('/config/options/'+type, { name, statusType })
    else
      await api.post('/config/options/'+type, { name })
    setName('')
    const { data } = await api.get('/config/options', { params: { types: type } })
    setRows(data[type])
  }
  async function save(r) {
    await api.put(`/config/options/${type}/${r.id}`, { name: r.name, is_active: r.is_active })
  }
  return (
    <div style={{ marginBottom: 24 }}>
      <h3>{title}</h3>
      <div style={{ display:'flex', gap:8, marginBottom:8 }}>
        {type === 'statuses' ? (
          <>
            <select value={statusType} onChange={e=>setStatusType(e.target.value)}>
              <option value="project_status">Project Status</option>
              <option value="invoice_status">Invoice Status</option>
              <option value="po_status">PO Status</option>
            </select>
          </>
        ) : null}
        <input placeholder="Name" value={name} onChange={e=>setName(e.target.value)} />
        <button onClick={add}>Add</button>
      </div>
      <table border="1" cellPadding="6" cellSpacing="0" width="100%">
        <thead><tr><th>Name</th><th>Active</th><th>Save</th></tr></thead>
        <tbody>
          {rows.map(r => (
            <tr key={r.id}>
              <td><input value={r.name} onChange={e=>setRows(list=>list.map(x=>x.id===r.id?{...x,name:e.target.value}:x))} /></td>
              <td><input type="checkbox" checked={!!r.is_active} onChange={e=>setRows(list=>list.map(x=>x.id===r.id?{...x,is_active:e.target.checked?1:0}:x))} /></td>
              <td><button onClick={()=>save(r)}>Save</button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default function Config() {
  const [data, setData] = useState({ customers: [], segments: [], service_lines: [], partners: [], statuses: [] })
  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,segments,service_lines,partners,statuses' } })
      setData(data)
    }
    load()
  }, [])
  return (
    <div>
      <h2>Dropdowns & Statuses</h2>
      <Editor title="Customers" type="customers" rows={data.customers} setRows={rows=>setData(s=>({...s, customers: rows}))} />
      <Editor title="Segments" type="segments" rows={data.segments} setRows={rows=>setData(s=>({...s, segments: rows}))} />
      <Editor title="Service Lines" type="service_lines" rows={data.service_lines} setRows={rows=>setData(s=>({...s, service_lines: rows}))} />
      <Editor title="Partners" type="partners" rows={data.partners} setRows={rows=>setData(s=>({...s, partners: rows}))} />
      <Editor title="Statuses" type="statuses" rows={data.statuses} setRows={rows=>setData(s=>({...s, statuses: rows}))} />
    </div>
  )
}
