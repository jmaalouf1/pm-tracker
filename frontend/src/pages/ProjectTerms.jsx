import React, { useEffect, useState } from 'react'
import api from '../services/api'
import { useParams } from 'react-router-dom'

export default function ProjectTerms() {
  const { id } = useParams()
  const [terms, setTerms] = useState([])
  const [statuses, setStatuses] = useState([])
  const [project, setProject] = useState(null)
  const [msg, setMsg] = useState('')

  async function load() {
    const p = await api.get('/projects/' + id)
    setProject(p.data)
    const { data } = await api.get(`/projects/${id}/terms`)
    setTerms(data.length ? data : [{ percentage: 100, description: 'Milestone 1', status_id: null }])
    const opt = await api.get('/config/options', { params: { types: 'statuses' } })
    setStatuses(opt.data.statuses.filter(s=>s.type==='term_status'))
  }

  useEffect(()=>{ load() }, [id])

  function addRow() {
    setTerms(ts=>[...ts, { percentage: 0, description: '', status_id: null }])
  }
  function update(i, k, v) {
    setTerms(ts=>ts.map((t,idx)=>idx===i?{...t,[k]:v}:t))
  }
  function sumPct() { return terms.reduce((a,b)=>a + Number(b.percentage||0), 0) }

  async function save() {
    setMsg('')
    const total = sumPct()
    if (Math.abs(total - 100) > 0.01) { setMsg('Percentages must sum to 100%. Current total: ' + total); return }
    await api.put(`/projects/${id}/terms`, { terms })
    setMsg('Saved')
    await load()
  }

  return (
    <div>
      <h2>Project Terms {project ? `— ${project.name}` : ''}</h2>
      <div className="card">
        <table>
          <thead><tr><th>#</th><th>Percentage</th><th>Description</th><th>Status</th></tr></thead>
          <tbody>
            {terms.map((t,i)=>(
              <tr key={i}>
                <td>{i+1}</td>
                <td><input type="number" step="0.01" value={t.percentage} onChange={e=>update(i,'percentage',e.target.value)} /></td>
                <td><input value={t.description} onChange={e=>update(i,'description',e.target.value)} /></td>
                <td>
                  <select value={t.status_id || ''} onChange={e=>update(i,'status_id', e.target.value ? Number(e.target.value) : null)}>
                    <option value="">--</option>
                    {statuses.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}
                  </select>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <div style={{ display:'flex', gap:8, marginTop:8, alignItems:'center' }}>
          <button onClick={addRow}>Add Row</button>
          <button className="primary" onClick={save}>Save Terms</button>
          <span> Total: <strong>{sumPct().toFixed(2)}%</strong></span>
          {msg ? <span>{msg}</span> : null}
        </div>
      </div>
    </div>
  )
}
