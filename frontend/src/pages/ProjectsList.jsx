import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { Link } from 'react-router-dom'
import SearchBox from '../components/SearchBox'
import Pagination from '../components/Pagination'

export default function ProjectsList() {
 const [rows, setRows] = useState([])
 const [q, setQ] = useState('')
 const [page, setPage] = useState(1)
 const [pageSize, setPageSize] = useState(20)
 const [total, setTotal] = useState(0)
 const [busy, setBusy] = useState(false)

 async function reload(p = page) {
 setBusy(true)
 const { data } = await api.get('/projects', { params: { q, page: p, pageSize } })
 setRows(data.data); setTotal(data.total); setPage(data.page)
 setBusy(false)
 }
 useEffect(() => { reload(1) }, [])
 useEffect(() => { const id = setTimeout(() => reload(1), 250); return () => clearTimeout(id) }, [q, pageSize])

 const pages = Math.max(1, Math.ceil(total / pageSize))

 return (
 <div className="card p-3">
 <div className="d-flex gap-3 align-items-center mb-3">
 <div className="flex-grow-1"><SearchBox value={q} onChange={setQ} placeholder="Search projects" /></div>
 <Link className="btn btn-primary btn-icon" to="/projects/new"> New Project</Link>
 </div>
 <div className="table-responsive">
 <table className="table table-sm table-hover align-middle">
 <thead><tr>
 <th className="text-muted">ID</th>
 <th>Name</th>
 <th>Customer</th>
 <th>Segment</th>
 <th>Status</th>
 <th className="text-end">Remaining %</th>
 <th className="text-end">Backlog</th>
 <th>Actions</th>
 </tr></thead>
 <tbody>
 {rows.map(r=>(
 <tr key={r.id}>
 <td className="text-muted">{r.id}</td>
 <td>{r.name}</td>
 <td>{r.customer||''}</td>
 <td>{r.segment||''}</td>
 <td><span className="badge bg-light text-dark">{r.status||''}</span></td>
 <td className="text-end">{Number(r.remaining_percent||0).toFixed(2)}%</td>
 <td className="text-end">{Number(r.backlog_amount||0).toLocaleString(undefined,{minimumFractionDigits:2,maximumFractionDigits:2})}</td>
 <td><Link to={`/projects/${r.id}/terms`} className="btn btn-sm btn-outline-primary">Manage Terms</Link></td>
 </tr>
 ))}
 {rows.length===0 && (
 <tr><td colSpan="8" className="text-center py-4 text-muted">{busy?'Loading…':'No projects found'}</td></tr>
 )}
 </tbody>
 </table>
 </div>
 <Pagination page={page} pages={pages} total={total} pageSize={pageSize}
 setPage={(p)=>{setPage(p); reload(p)}} setPageSize={setPageSize} />
 </div>
 )
}
