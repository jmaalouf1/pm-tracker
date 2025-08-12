import React, { useEffect, useState } from 'react'
import api from '../services/api'

export default function ProjectNew() {
  const [form, setForm] = useState({ name: '' })
  const [opts, setOpts] = useState({ customers: [], segments: [], service_lines: [], partners: [], statuses: [] , payment_terms: []})

  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,segments,service_lines,partners,statuses' } })
      const pt = await api.get('/payment-terms')
      setOpts({ ...data, payment_terms: pt.data })
    }
    load()
  }, [])

  function change(k, v) { setForm(s => ({ ...s, [k]: v })) }

  async function submit(e) {
    e.preventDefault()
    await api.post('/projects', form)
    alert('Project created')
    setForm({ name: '' })
  }

  const dd = (name, list, extra = (o)=>o.name) => (
    <select value={form[name] || ''} onChange={e=>change(name, e.target.value || null)}>
      <option value="">--</option>
      {list.map(o => <option key={o.id} value={o.id}>{extra(o)}</option>)}
    </select>
  )

  return (
    <form onSubmit={submit} style={{ maxWidth: 600 }}>
      <h2>New Project</h2>
      <div><label>Name</label><input value={form.name} onChange={e=>change('name', e.target.value)} required /></div>
      <div><label>Customer</label>{dd('customer_id', opts.customers)}</div>
      <div><label>Segment</label>{dd('segment_id', opts.segments)}</div>
      <div><label>Service Line</label>{dd('service_line_id', opts.service_lines)}</div>
      <div><label>Partner</label>{dd('partner_id', opts.partners)}</div>
      <div><label>Payment Terms</label>{dd('payment_term_id', opts.payment_terms, o => `${o.name} (${o.days}d)`)}</div>
      <div><label>Status</label>{dd('status_id', opts.statuses.filter(s=>s.type==='project_status'))}</div>
      <div><label>PO Status</label>{dd('po_status_id', opts.statuses.filter(s=>s.type==='po_status'))}</div>
      <div><label>Invoice Status</label>{dd('invoice_status_id', opts.statuses.filter(s=>s.type==='invoice_status'))}</div>
      <div><label>Backlog 2025</label><input type="number" step="0.01" value={form.backlog_2025 || ''} onChange={e=>change('backlog_2025', e.target.value)} /></div>
      <button type="submit">Create</button>
    </form>
  )
}
