import React, { useEffect, useState } from 'react'
import api from '../services/api'

export default function PaymentTerms() {
  const [rows, setRows] = useState([])
  const [form, setForm] = useState({ name: '', days: 0, description: '' })

  async function load() {
    const { data } = await api.get('/payment-terms')
    setRows(data)
  }
  useEffect(() => { load() }, [])

  async function add(e) {
    e.preventDefault()
    await api.post('/payment-terms', form)
    setForm({ name: '', days: 0, description: '' })
    await load()
  }
  async function save(r) {
    await api.put('/payment-terms/'+r.id, r)
    await load()
  }
  async function remove(id) {
    if (!confirm('Delete?')) return
    await api.delete('/payment-terms/'+id)
    await load()
  }

  return (
    <div>
      <h2>Payment Terms</h2>
      <form onSubmit={add} style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
        <input placeholder="Name" value={form.name} onChange={e=>setForm(s=>({...s,name:e.target.value}))} required />
        <input type="number" placeholder="Days" value={form.days} onChange={e=>setForm(s=>({...s,days:+e.target.value}))} />
        <input placeholder="Description" value={form.description} onChange={e=>setForm(s=>({...s,description:e.target.value}))} />
        <button>Add</button>
      </form>
      <table border="1" cellPadding="6" cellSpacing="0" width="100%">
        <thead><tr><th>Name</th><th>Days</th><th>Description</th><th>Actions</th></tr></thead>
        <tbody>
          {rows.map(r => (
            <tr key={r.id}>
              <td><input value={r.name} onChange={e=>setRows(rs=>rs.map(x=>x.id===r.id?{...x,name:e.target.value}:x))} /></td>
              <td><input type="number" value={r.days} onChange={e=>setRows(rs=>rs.map(x=>x.id===r.id?{...x,days:+e.target.value}:x))} /></td>
              <td><input value={r.description || ''} onChange={e=>setRows(rs=>rs.map(x=>x.id===r.id?{...x,description:e.target.value}:x))} /></td>
              <td>
                <button onClick={()=>save(r)}>Save</button>
                <button onClick={()=>remove(r.id)}>Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
