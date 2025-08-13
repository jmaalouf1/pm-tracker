// frontend/src/pages/Customers.jsx
import React,{useEffect,useState} from 'react'
import { apiFetch } from '../lib/api'

export default function Customers(){
  const [q,setQ]=useState('')
  const [rows,setRows]=useState([])
  const [loading,setLoading]=useState(false)
  const [err,setErr]=useState(null)

  const [creating,setCreating]=useState(false)
  const [form,setForm]=useState({name:'',country:'',type:'',cr:'',vat:''})
  const [saving,setSaving]=useState(false)
  const [saveErr,setSaveErr]=useState(null)

  async function load(){
    setLoading(true); setErr(null)
    try{
      const res=await apiFetch(`/api/customers?search=${encodeURIComponent(q)}`)
      if(!res.ok) throw new Error(`Failed to load customers: ${res.status}`)
      const data=await res.json()
      setRows(Array.isArray(data?.rows)?data.rows:(Array.isArray(data)?data:[]))
    }catch(e){ setErr(e) }finally{ setLoading(false) }
  }
  useEffect(()=>{ load() },[])

  async function onCreate(e){
    e.preventDefault()
    if(!form.name.trim()) { setSaveErr(new Error('Name is required')); return }
    setSaving(true); setSaveErr(null)
    try{
      const res=await apiFetch('/api/customers',{
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body:JSON.stringify({
          name:form.name.trim(),
          country:form.country||null,
          type:form.type||null,
          commercial_registration:form.cr||null,
          vat_number:form.vat||null,
        })
      })
      const out=await res.json().catch(()=> ({}))
      if(!res.ok) throw new Error(out?.message||`Create failed (${res.status})`)
      setCreating(false); setForm({name:'',country:'',type:'',cr:'',vat:''})
      load()
    }catch(e){ setSaveErr(e) }finally{ setSaving(false) }
  }

  return (
    <div className="container-page py-3">
      <div className="d-flex justify-content-between align-items-center mb-3">
        <h3 className="mb-0">Customers</h3>
        <button className="btn btn-primary" onClick={()=>setCreating(v=>!v)}>{creating?'Close':'Add Customer'}</button>
      </div>

      {creating && (
        <div className="card p-3 mb-3">
          <h5 className="mb-2">New Customer</h5>
          <form className="row g-2" onSubmit={onCreate}>
            <div className="col-sm-4">
              <label className="form-label">Name *</label>
              <input className="form-control" value={form.name} onChange={e=>setForm({...form, name:e.target.value})} />
            </div>
            <div className="col-sm-2">
              <label className="form-label">Country (ISO2)</label>
              <input className="form-control" maxLength={2} value={form.country} onChange={e=>setForm({...form, country:e.target.value.toUpperCase()})} />
            </div>
            <div className="col-sm-2">
              <label className="form-label">Type</label>
              <select className="form-select" value={form.type} onChange={e=>setForm({...form, type:e.target.value})}>
                <option value="">--</option>
                <option>Bank</option><option>Fintech</option><option>Digital Bank</option>
                <option>Government Entity</option><option>NFI</option><option>Other</option>
              </select>
            </div>
            <div className="col-sm-2">
              <label className="form-label">CR</label>
              <input className="form-control" value={form.cr} onChange={e=>setForm({...form, cr:e.target.value})} />
            </div>
            <div className="col-sm-2">
              <label className="form-label">VAT</label>
              <input className="form-control" value={form.vat} onChange={e=>setForm({...form, vat:e.target.value})} />
            </div>
            <div className="col-12 d-flex gap-2 mt-2">
              <button className="btn btn-success" disabled={saving}>{saving?'Saving…':'Save'}</button>
              <button type="button" className="btn btn-outline-secondary" onClick={()=>{setCreating(false); setSaveErr(null)}}>Cancel</button>
            </div>
            {saveErr && <div className="col-12"><div className="alert alert-danger mt-2">{String(saveErr.message||saveErr)}</div></div>}
          </form>
        </div>
      )}

      <div className="card p-3">
        <div className="d-flex gap-2 mb-2">
          <input className="form-control" placeholder="Search by name/CR/VAT" value={q} onChange={e=>setQ(e.target.value)} />
          <button className="btn btn-outline-primary" onClick={load} disabled={loading}>{loading?'Searching…':'Search'}</button>
        </div>
        {err && <div className="alert alert-warning">{String(err.message||err)}</div>}
        <div className="table-responsive">
          <table className="table align-middle">
            <thead><tr><th>Name</th><th>Country</th><th>Type</th><th>CR</th><th>VAT</th></tr></thead>
            <tbody>
              {rows.length ? rows.map((c,i)=>(
                <tr key={c.id||i}>
                  <td>{c.name}</td>
                  <td>{c.country||c.country_iso2||''}</td>
                  <td>{c.type||''}</td>
                  <td>{c.commercial_registration||c.cr||''}</td>
                  <td>{c.vat_number||c.vat||''}</td>
                </tr>
              )) : (
                <tr><td colSpan="5" className="text-center text-muted">{loading?'Loading…':'No results'}</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
