import React, { useEffect, useState } from 'react'
import api from '../services/api'

export default function ProjectNew() {
  const [form, setForm] = useState({ name: '', contract_value: 0 })
  const [opts, setOpts] = useState({ customers: [], segments: [], service_lines: [], partners: [], statuses: [] })

  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,segments,service_lines,partners,statuses' } })
      setOpts(data)
    }
    load()
  }, [])

  function change(k, v) { setForm(s => ({ ...s, [k]: v })) }

  async function submit(e) {
    e.preventDefault()
    await api.post('/projects', form)
    alert('Project created')
    setForm({ name: '', contract_value: 0 })
  }

  const dd = (name, list, extra = (o)=>o.name) => (
    <select value={form[name] || ''} onChange={e=>change(name, e.target.value || null)}>
      <option value="">--</option>
      {list.map(o => <option key={o.id} value={o.id}>{extra(o)}</option>)}
    </select>
  )

  return (
    <form onSubmit={submit} style={{ maxWidth: 700 }}>
      <h2>New Project</h2>
      <div className="grid">
        <div className="col-8">
          <label>Name</label><input value={form.name} onChange={e=>change('name', e.target.value)} required />
        </div>
        <div className="col-4">
          <label>Contract Value</label><input type="number" step="0.01" value={form.contract_value || 0} onChange={e=>change('contract_value', e.target.value)} />
        </div>
        <div className="col-6"><label>Customer</label>{dd('customer_id', opts.customers)}</div>
        <div className="col-6"><label>Segment</label>{dd('segment_id', opts.segments)}</div>
        <div className="col-6"><label>Service Line</label>{dd('service_line_id', opts.service_lines)}</div>
        <div className="col-6"><label>Partner</label>{dd('partner_id', opts.partners)}</div>
        <div className="col-4"><label>Status</label>{dd('status_id', opts.statuses.filter(s=>s.type==='project_status'))}</div>
        <div className="col-4"><label>PO Status</label>{dd('po_status_id', opts.statuses.filter(s=>s.type==='po_status'))}</div>
        <div className="col-4"><label>Invoice Status</label>{dd('invoice_status_id', opts.statuses.filter(s=>s.type==='invoice_status'))}</div>
      </div>
      <button className="primary" type="submit">Create</button>
    </form>
  )
}
