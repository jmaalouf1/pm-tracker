import "../app.css"
import React, { useEffect, useState } from 'react'
import api from '../services/api'

function Editor({ title, type, rows, setRows }) {
 const [name, setName] = useState('')
 const [statusType, setStatusType] = useState('project_status')
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
 <div className="card shadow-sm mb-4">
 <div className="card-body">
 <h5 className="mb-3">{title}</h5>
 <div className="d-flex gap-2 mb-2">
 {type === 'statuses' ? (
 <select className="form-select w-auto" value={statusType} onChange={e=>setStatusType(e.target.value)}>
 <option value="project_status">Project Status</option>
 <option value="invoice_status">Invoice Status</option>
 <option value="po_status">PO Status</option>
 <option value="term_status">Term Status</option>
 </select>
 ) : null}
 <input className="form-control" placeholder="Name" value={name} onChange={e=>setName(e.target.value)} />
 <button className="btn btn-outline-secondary" onClick={add}>Add</button>
 </div>
 <div className="table-responsive">
 <table className="table table-sm">
 <thead><tr><th>Name</th><th>Active</th><th>Save</th></tr></thead>
 <tbody>
 {rows.map(r => (
 <tr key={r.id}>
 <td><input className="form-control form-control-sm" value={r.name} onChange={e=>setRows(list=>list.map(x=>x.id===r.id?{...x,name:e.target.value}:x))} /></td>
 <td><input type="checkbox" checked={!!r.is_active} onChange={e=>setRows(list=>list.map(x=>x.id===r.id?{...x,is_active:e.target.checked?1:0}:x))} /></td>
 <td><button className="btn btn-sm btn-outline-primary" onClick={()=>save(r)}>Save</button></td>
 </tr>
 ))}
 </tbody>
 </table>
 </div>
 </div>
 </div>
 )
}

export default function Config() {
 const [data, setData] = useState({ segments: [], service_lines: [], partners: [], statuses: [] })
 useEffect(() => {
 async function load() {
 const { data } = await api.get('/config/options', { params: { types: 'segments,service_lines,partners,statuses,customers' } })
 setData(data)
 }
 load()
 }, [])
 return (
 <div>
 <h2 className="mb-3">Dropdowns & Statuses</h2>
 <Editor title="Segments" type="segments" rows={data.segments||[]} setRows={rows=>setData(s=>({...s, segments: rows}))} />
 <Editor title="Service Lines" type="service_lines" rows={data.service_lines||[]} setRows={rows=>setData(s=>({...s, service_lines: rows}))} />
 <Editor title="Partners" type="partners" rows={data.partners||[]} setRows={rows=>setData(s=>({...s, partners: rows}))} />
 <Editor title="Statuses" type="statuses" rows={data.statuses||[]} setRows={rows=>setData(s=>({...s, statuses: rows}))} />
 </div>
 )
}
