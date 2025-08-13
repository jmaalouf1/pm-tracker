import "../app.css"
import React, { useEffect, useState } from 'react'
import api from '../services/api'

const TYPES = [
 { value: 'bank', label: 'Bank' },
 { value: 'fintech', label: 'Fintech' },
 { value: 'digital_bank', label: 'Digital Bank' },
 { value: 'government', label: 'Government Entity' },
 { value: 'nfi', label: 'NFI' },
 { value: 'other', label: 'Other' },
]

export default function Customers() {
 const [rows, setRows] = useState([])
 const [q, setQ] = useState('')
 const [page, setPage] = useState(1)
 const [pageSize, setPageSize] = useState(20)
 const [total, setTotal] = useState(0)

 async function load(p=page){
 const { data } = await api.get('/customers', { params: { q, page: p, pageSize } })
 setRows(data.data || data) // depending on your current endpoint shape
 setTotal(data.total || data.length || 0)
 setPage(data.page || p)
 }
 useEffect(()=>{ load(1) },[])
 useEffect(()=>{ const id=setTimeout(()=>load(1),250); return ()=>clearTimeout(id) },[q,pageSize])

 const pages = Math.max(1, Math.ceil((total||0)/pageSize))

 return (
 <div>
 <h2 className="mb-3">Customers</h2>
 <div className="d-flex gap-2 mb-3">
 <input className="form-control" placeholder="Search by name/CR/VAT…" value={q} onChange={e=>setQ(e.target.value)} />
 </div>

 <div className="table-responsive shadow-sm">
 <table className="table table-sm table-striped align-middle">
 <thead><tr><th>Name</th><th>Country</th><th>Type</th><th>CR</th><th>VAT</th><th>#Contacts</th></tr></thead>
 <tbody>
 {rows.map(r => (
 <tr key={r.id}>
 <td>{r.name}</td>
 <td>{r.country ? <span>{r.country} <span className="text-primary small">•</span></span> : ''}</td>
 <td>{r.type || ''}</td>
 <td>{r.commercial_registration || ''}</td>
 <td>{r.vat_number || ''}</td>
 <td>{r.contacts_count || 0}</td>
 </tr>
 ))}
 </tbody>
 </table>
 </div>

 <div className="d-flex justify-content-between align-items-center mt-2">
 <div className="d-flex align-items-center gap-2">
 <span>Rows:</span>
 <select className="form-select form-select-sm" style={{width:'auto'}} value={pageSize} onChange={e=>setPageSize(Number(e.target.value))}>
 {[10,20,50,100].map(n => <option key={n} value={n}>{n}</option>)}
 </select>
 <span className="text-muted">Total: {total}</span>
 </div>
 <div className="btn-group">
 <button className="btn btn-sm btn-outline-secondary" disabled={page<=1} onClick={()=>{setPage(1);load(1)}}>First</button>
 <button className="btn btn-sm btn-outline-secondary" disabled={page<=1} onClick={()=>{setPage(page-1);load(page-1)}}>Prev</button>
 <span className="btn btn-sm btn-light disabled">{page} / {pages}</span>
 <button className="btn btn-sm btn-outline-secondary" disabled={page>=pages} onClick={()=>{setPage(page+1);load(page+1)}}>Next</button>
 <button className="btn btn-sm btn-outline-secondary" disabled={page>=pages} onClick={()=>{setPage(pages);load(pages)}}>Last</button>
 </div>
 </div>
 </div>
 )
}
