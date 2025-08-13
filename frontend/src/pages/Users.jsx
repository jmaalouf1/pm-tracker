import "../app.css"
import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../context/AuthContext'

const ROLES = ['super_admin','pm_admin','pm_user','finance']

export default function Users(){
 const { user } = useAuth()
 const [rows, setRows] = useState([])
 const [customers, setCustomers] = useState([])
 const [busy, setBusy] = useState(false)
 const [form, setForm] = useState({ name:'', email:'', password:'', role:'pm_user' })
 const [assigning, setAssigning] = useState(null)
 const [selected, setSelected] = useState([])
 const isAdmin = user && (user.role === 'super_admin' || user.role === 'pm_admin')

 async function load(){
 setBusy(true)
 const u = await api.get('/users'); setRows(u.data)
 const c = await api.get('/config/options', { params: { types: 'customers' } })
 setCustomers(c.data.customers || [])
 setBusy(false)
 }
 useEffect(()=>{ load() },[])

 async function create(e){
 e.preventDefault()
 await api.post('/users', form)
 setForm({ name:'', email:'', password:'', role:'pm_user' })
 await load()
 }
 async function openAssign(u){
 setAssigning(u)
 const { data } = await api.get('/users/'+u.id+'/customers')
 setSelected(data.map(d=>d.customer_id))
 }
 function toggle(cid){ setSelected(s => s.includes(cid) ? s.filter(x=>x!==cid) : [...s, cid]) }
 async function saveAssign(){ await api.put('/users/'+assigning.id+'/customers', { customer_ids: selected }); setAssigning(null); setSelected([]); await load() }
 async function changeRole(u, role){ await api.patch('/users/'+u.id+'/role', { role }); await load() }

 if (!isAdmin) return <div className="alert alert-warning">You need admin permissions to manage users.</div>

 return (
 <div>
 <h2 className="mb-3">Users</h2>
 <div className="card shadow-sm mb-4">
 <div className="card-body">
 <h5 className="mb-3">Create User</h5>
 <form onSubmit={create} className="row g-3">
 <div className="col-md-3"><label className="form-label">Name</label><input className="form-control" value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} required /></div>
 <div className="col-md-3"><label className="form-label">Email</label><input className="form-control" type="email" value={form.email} onChange={e=>setForm(f=>({...f,email:e.target.value}))} required /></div>
 <div className="col-md-3"><label className="form-label">Password</label><input className="form-control" type="password" value={form.password} onChange={e=>setForm(f=>({...f,password:e.target.value}))} required /></div>
 <div className="col-md-2"><label className="form-label">Role</label>
 <select className="form-select" value={form.role} onChange={e=>setForm(f=>({...f,role:e.target.value}))}>{ROLES.map(r=> <option key={r} value={r}>{r}</option>)}</select>
 </div>
 <div className="col-md-1 d-flex align-items-end"><button className="btn btn-primary" disabled={busy}>Create</button></div>
 </form>
 </div>
 </div>

 <div className="table-responsive shadow-sm">
 <table className="table table-sm table-striped align-middle">
 <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Role</th><th>#Customers</th><th>Actions</th></tr></thead>
 <tbody>
 {rows.map(u=>(
 <tr key={u.id}>
 <td>{u.id}</td><td>{u.name}</td><td>{u.email}</td>
 <td style={{width:220}}>
 <select className="form-select form-select-sm" value={u.role} onChange={e=>changeRole(u, e.target.value)}>
 {ROLES.map(r=> <option key={r} value={r}>{r}</option>)}
 </select>
 </td>
 <td>{u.customers_count}</td>
 <td><button className="btn btn-sm btn-outline-primary" onClick={()=>openAssign(u)}>Manage Customers</button></td>
 </tr>
 ))}
 </tbody>
 </table>
 </div>

 {assigning && (
 <div className="card shadow-sm mt-3">
 <div className="card-body">
 <h5 className="mb-2">Assign Customers to {assigning.name}</h5>
 <div className="row g-2">
 {customers.map(c=>(
 <div key={c.id} className="col-md-3">
 <label className="form-check">
 <input type="checkbox" className="form-check-input" checked={selected.includes(c.id)} onChange={()=>toggle(c.id)} />
 <span className="form-check-label">{c.name} {c.country ? <span className="text-primary small ms-1">{c.country}</span> : null}</span>
 </label>
 </div>
 ))}
 </div>
 <div className="mt-3 d-flex gap-2">
 <button className="btn btn-primary" onClick={saveAssign}>Save</button>
 <button className="btn btn-outline-secondary" onClick={()=>{ setAssigning(null); setSelected([]); }}>Cancel</button>
 </div>
 </div>
 </div>
 )}
 </div>
 )
}
