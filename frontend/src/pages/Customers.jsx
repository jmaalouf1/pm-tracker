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
      <h2>Customers</h2>
      <div style={{ display:'flex', gap:8, marginBottom:12 }}>
        <input placeholder="Search by name/CR/VAT..." value={q} onChange={e=>setQ(e.target.value)} />
        <button className="primary" onClick={load}>Search</button>
        <button onClick={()=>setShowNew(s=>!s)} className="primary">{showNew?'Close':'New Customer'}</button>
      </div>

      {showNew && (
        <div className="card" style={{ marginBottom: 16 }}>
          <form onSubmit={create}>
            <div className="grid">
              <div className="col-6">
                <label>Name</label>
                <input required value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} />
              </div>
              <div className="col-2">
                <label>Country (ISO2)</label>
                <input placeholder="SA" value={form.country||''} onChange={e=>setForm(f=>({...f,country:e.target.value.toUpperCase()}))} />
              </div>
              <div className="col-4">
                <label>Type</label>
                <select value={form.type||''} onChange={e=>setForm(f=>({...f,type:e.target.value||null}))}>
                  <option value="">--</option>
                  {TYPES.map(t=><option key={t.value} value={t.value}>{t.label}</option>)}
                </select>
              </div>
              <div className="col-6">
                <label>Commercial Registration</label>
                <input value={form.commercial_registration||''} onChange={e=>setForm(f=>({...f,commercial_registration:e.target.value}))} />
              </div>
              <div className="col-6">
                <label>VAT Number</label>
                <input value={form.vat_number||''} onChange={e=>setForm(f=>({...f,vat_number:e.target.value}))} />
              </div>
              <div className="col-12">
                <h4>Contacts</h4>
                <div className="grid">
                  <div className="col-3"><label>Role</label><input value={contact.role} onChange={e=>setContact(c=>({...c,role:e.target.value}))} /></div>
                  <div className="col-3"><label>Name</label><input value={contact.name} onChange={e=>setContact(c=>({...c,name:e.target.value}))} /></div>
                  <div className="col-3"><label>Email</label><input type="email" value={contact.email} onChange={e=>setContact(c=>({...c,email:e.target.value}))} /></div>
                  <div className="col-2"><label>Phone</label><input value={contact.phone} onChange={e=>setContact(c=>({...c,phone:e.target.value}))} /></div>
                  <div className="col-1"><label>&nbsp;</label><button type="button" onClick={addContact}>Add</button></div>
                </div>
                {(form.contacts||[]).length ? (
                  <table style={{ marginTop: 8 }}>
                    <thead><tr><th>Role</th><th>Name</th><th>Email</th><th>Phone</th></tr></thead>
                    <tbody>
                      {form.contacts.map((c,i)=>(<tr key={i}><td>{c.role}</td><td>{c.name}</td><td>{c.email}</td><td>{c.phone}</td></tr>))}
                    </tbody>
                  </table>
                ): null}
              </div>
              <div className="col-12"><button className="primary">Create Customer</button></div>
            </div>
          </form>
        </div>
      )}

      <table>
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
  )
}
