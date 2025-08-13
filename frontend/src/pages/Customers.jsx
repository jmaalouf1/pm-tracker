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
  const [showNew, setShowNew] = useState(false)
  const [form, setForm] = useState({ name: '', country: '', type: '', commercial_registration: '', vat_number: '', contacts: [] })
  const [contact, setContact] = useState({ role:'', name:'', email:'', phone:'' })

  async function load() {
    const { data } = await api.get('/customers', { params: q ? { q } : undefined })
    setRows(data)
  }
  useEffect(()=>{ load() }, [])

  function addContact() {
    if (!contact.name) return
    setForm(f => ({ ...f, contacts: [...(f.contacts||[]), contact] }))
    setContact({ role:'', name:'', email:'', phone:'' })
  }

  async function create(e) {
    e.preventDefault()
    await api.post('/customers', form)
    setShowNew(false)
    setForm({ name: '', country: '', type: '', commercial_registration: '', vat_number: '', contacts: [] })
    await load()
  }

  return (
    <div>
      <h2 className="mb-3">Customers</h2>
      <div className="d-flex gap-2 mb-3">
        <input className="form-control" placeholder="Search by name/CR/VAT…" value={q} onChange={e=>setQ(e.target.value)} />
        <button className="btn btn-outline-secondary" onClick={load}>Search</button>
        <button className="btn btn-primary" onClick={()=>setShowNew(s=>!s)}>{showNew?'Close':'New Customer'}</button>
      </div>

      {showNew && (
        <div className="card shadow-sm mb-4">
          <div className="card-body">
            <h5 className="card-title mb-3">New Customer</h5>
            <form onSubmit={create}>
              <div className="row g-3">
                <div className="col-md-6">
                  <label className="form-label">Name</label>
                  <input className="form-control" required value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} />
                </div>
                <div className="col-md-2">
                  <label className="form-label">Country (ISO2)</label>
                  <input className="form-control text-uppercase" placeholder="SA" value={form.country||''} onChange={e=>setForm(f=>({...f,country:e.target.value.toUpperCase()}))} />
                </div>
                <div className="col-md-4">
                  <label className="form-label">Type</label>
                  <select className="form-select" value={form.type||''} onChange={e=>setForm(f=>({...f,type:e.target.value||null}))}>
                    <option value="">--</option>
                    {TYPES.map(t=><option key={t.value} value={t.value}>{t.label}</option>)}
                  </select>
                </div>

                <div className="col-md-6">
                  <label className="form-label">Commercial Registration</label>
                  <input className="form-control" value={form.commercial_registration||''} onChange={e=>setForm(f=>({...f,commercial_registration:e.target.value}))} />
                </div>
                <div className="col-md-6">
                  <label className="form-label">VAT Number</label>
                  <input className="form-control" value={form.vat_number||''} onChange={e=>setForm(f=>({...f,vat_number:e.target.value}))} />
                </div>

                <div className="col-12 mt-2">
                  <h6 className="mb-2">Contacts</h6>
                  <div className="row g-2 align-items-end">
                    <div className="col-md-3">
                      <label className="form-label">Role</label>
                      <input className="form-control" value={contact.role} onChange={e=>setContact(c=>({...c,role:e.target.value}))} />
                    </div>
                    <div className="col-md-3">
                      <label className="form-label">Name</label>
                      <input className="form-control" value={contact.name} onChange={e=>setContact(c=>({...c,name:e.target.value}))} />
                    </div>
                    <div className="col-md-3">
                      <label className="form-label">Email</label>
                      <input className="form-control" type="email" value={contact.email} onChange={e=>setContact(c=>({...c,email:e.target.value}))} />
                    </div>
                    <div className="col-md-2">
                      <label className="form-label">Phone</label>
                      <input className="form-control" value={contact.phone} onChange={e=>setContact(c=>({...c,phone:e.target.value}))} />
                    </div>
                    <div className="col-md-1">
                      <button type="button" className="btn btn-outline-secondary w-100" onClick={addContact}>Add</button>
                    </div>
                  </div>

                  {(form.contacts||[]).length ? (
                    <div className="table-responsive mt-3">
                      <table className="table table-sm table-striped">
                        <thead><tr><th>Role</th><th>Name</th><th>Email</th><th>Phone</th></tr></thead>
                        <tbody>
                          {form.contacts.map((c,i)=>(<tr key={i}><td>{c.role}</td><td>{c.name}</td><td>{c.email}</td><td>{c.phone}</td></tr>))}
                        </tbody>
                      </table>
                    </div>
                  ): null}
                </div>

                <div className="col-12">
                  <button className="btn btn-primary">Create Customer</button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="table-responsive shadow-sm">
        <table className="table table-sm table-striped align-middle">
          <thead><tr><th>Name</th><th>Country</th><th>Type</th><th>CR</th><th>VAT</th><th>#Contacts</th></tr></thead>
          <tbody>
            {rows.map(r => (
              <tr key={r.id}>
                <td>{r.name}</td>
                <td>{r.country || ''}</td>
                <td>{r.type || ''}</td>
                <td>{r.commercial_registration || ''}</td>
                <td>{r.vat_number || ''}</td>
                <td>{r.contacts_count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
