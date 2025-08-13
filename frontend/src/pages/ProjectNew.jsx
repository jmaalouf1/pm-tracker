import React, { useEffect, useMemo, useState } from 'react'
import api from '../services/api'
function clamp(n){ n=Number(n||0); if(isNaN(n)) n=0; return Math.max(0, Math.min(100, n)) }

export default function ProjectNew() {
  const [form, setForm] = useState({ name: '', contract_value: 0 })
  const [opts, setOpts] = useState({ customers: [], segments: [], service_lines: [], partners: [], statuses: [] })
  const [terms, setTerms] = useState([{ percentage: 100, description: 'Milestone 1', status_id: null }])
  const total = useMemo(()=> terms.reduce((a,b)=>a+clamp(b.percentage),0), [terms])
  const termsValid = Math.abs(total-100)<=0.01 && terms.every(t=>String(t.description||'').trim().length)

  useEffect(() => {
    async function load() {
      const { data } = await api.get('/config/options', { params: { types: 'customers,segments,service_lines,partners,statuses' } })
      setOpts(data)
    }
    load()
  }, [])

  function change(k, v) { setForm(s => ({ ...s, [k]: v })) }
  function addRow(){ setTerms(ts=>[...ts,{ percentage:0, description:'', status_id:null }]) }
  function upd(i,k,v){ setTerms(ts=>ts.map((t,idx)=> idx===i? {...t,[k]:k==='percentage'?clamp(v):v }:t)) }
  function del(i){ setTerms(ts=> ts.filter((_,idx)=> idx!==i)) }

  const dd = (name, list) => (
    <select className="form-select" value={form[name] || ''} onChange={e=>change(name, e.target.value || null)}>
      <option value="">--</option>
      {list.map(o => <option key={o.id} value={o.id}>{o.name}</option>)}
    </select>
  )

  async function submit(e) {
    e.preventDefault()
    if (!termsValid) { alert('Payment terms must total 100% and each row needs a description.'); return }
    // 1) Create project
    const { data: created } = await api.post('/projects', form)
    const id = created.id || created.insertId || created.project_id || created?.data?.id
    if (!id) { alert('Project created but no ID returned.'); return }
    // 2) Save terms immediately (user perceives it as single creation flow)
    await api.put(`/projects/${id}/terms`, { terms: terms.map((t,idx)=> ({ ...t, seq: idx+1, percentage: clamp(t.percentage) })) })
    alert('Project created with payment terms.')
    window.location.href = `/projects/${id}/terms`
  }

  return (
    <form onSubmit={submit} className="card shadow-sm">
      <div className="card-body">
        <h4 className="mb-3">New Project</h4>
        <div className="row g-3">
          <div className="col-md-8">
            <label className="form-label">Name</label>
            <input className="form-control" value={form.name} onChange={e=>change('name', e.target.value)} required />
          </div>
          <div className="col-md-4">
            <label className="form-label">Contract Value</label>
            <input className="form-control" type="number" step="0.01" value={form.contract_value || 0} onChange={e=>change('contract_value', e.target.value)} />
          </div>
          <div className="col-md-6"><label className="form-label">Customer</label>{dd('customer_id', opts.customers)}</div>
          <div className="col-md-6"><label className="form-label">Segment</label>{dd('segment_id', opts.segments)}</div>
          <div className="col-md-6"><label className="form-label">Service Line</label>{dd('service_line_id', opts.service_lines)}</div>
          <div className="col-md-6"><label className="form-label">Partner</label>{dd('partner_id', opts.partners)}</div>
          <div className="col-md-4"><label className="form-label">Status</label>{dd('status_id', opts.statuses.filter(s=>s.type==='project_status'))}</div>
          <div className="col-md-4"><label className="form-label">PO Status</label>{dd('po_status_id', opts.statuses.filter(s=>s.type==='po_status'))}</div>
          <div className="col-md-4"><label className="form-label">Invoice Status</label>{dd('invoice_status_id', opts.statuses.filter(s=>s.type==='invoice_status'))}</div>
        </div>

        <hr className="my-4" />
        <h5 className="mb-3">Payment Terms (must total 100%)</h5>
        <div className="table-responsive">
          <table className="table table-sm align-middle">
            <thead><tr><th>#</th><th className="text-end">%</th><th>Description</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {terms.map((t,i)=>(
                <tr key={i}>
                  <td>{i+1}</td>
                  <td style={{width:130}} className="text-end">
                    <input type="number" min="0" max="100" step="0.01" className="form-control form-control-sm text-end"
                           value={t.percentage} onChange={e=>upd(i,'percentage',e.target.value)} />
                  </td>
                  <td><input className="form-control form-control-sm" value={t.description} onChange={e=>upd(i,'description',e.target.value)} placeholder="e.g. UAT sign-off" /></td>
                  <td style={{width:220}}>
                    <select className="form-select form-select-sm" value={t.status_id||''} onChange={e=>upd(i,'status_id', e.target.value?Number(e.target.value):null)}>
                      <option value="">--</option>
                      {(opts.statuses||[]).filter(s=>s.type==='term_status').map(s=><option key={s.id} value={s.id}>{s.name}</option>)}
                    </select>
                  </td>
                  <td style={{width:90}}><button type="button" className="btn btn-sm btn-outline-danger" onClick={()=>del(i)}>Remove</button></td>
                </tr>
              ))}
            </tbody>
            <tfoot><tr><th>Total</th><th className="text-end">{total.toFixed(2)}%</th><th colSpan="3"></th></tr></tfoot>
          </table>
        </div>
        <div className="d-flex gap-2">
          <button type="button" className="btn btn-outline-secondary" onClick={addRow}>Add Row</button>
          <button className="btn btn-primary" disabled={!termsValid}>Create Project with Terms</button>
        </div>
      </div>
    </form>
  )
}
