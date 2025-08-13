import "../app.css"
import React, { useEffect, useMemo, useState } from 'react'
import api from '../services/api'
import { useParams } from 'react-router-dom'
function clamp(n){ n=Number(n||0); if(isNaN(n)) n=0; return Math.max(0, Math.min(100, n)) }
export default function ProjectTerms(){
 const { id } = useParams()
 const [terms, setTerms] = useState([])
 const [statuses, setStatuses] = useState([])
 const [project, setProject] = useState(null)
 const [msg, setMsg] = useState('')
 const total = useMemo(()=> terms.reduce((a,b)=>a+clamp(b.percentage),0), [terms])
 const valid = Math.abs(total-100)<=0.01 && terms.every(t=>String(t.description||'').trim().length)
 async function load(){
 const p = await api.get('/projects/'+id); setProject(p.data)
 const list = await api.get('/projects/'+id+'/terms'); setTerms(list.data.length?list.data:[{percentage:100,description:'Milestone 1',status_id:null}])
 const opt = await api.get('/config/options',{params:{types:'statuses'}}); setStatuses(opt.data.statuses.filter(s=>s.type==='term_status'))
 }
 useEffect(()=>{ load() },[id])
 function addRow(){ setTerms(ts=>[...ts,{percentage:0,description:'',status_id:null}]) }
 function upd(i,k,v){ setTerms(ts=>ts.map((t,idx)=>idx===i?{...t,[k]:k==='percentage'?clamp(v):v}:t)) }
 function del(i){ setTerms(ts=>ts.filter((_,idx)=>idx!==i)) }
 async function save(){ setMsg(''); if(!valid){ setMsg('Descriptions required and total must be 100%. Current: '+total.toFixed(2)+'%'); return }
 await api.put('/projects/'+id+'/terms',{terms:terms.map((t,idx)=>({...t,seq:idx+1,percentage:clamp(t.percentage)}))})
 setMsg('Saved'); await load()
 }
 return (
 <div className="card shadow-sm">
 <div className="card-body">
 <h4 className="mb-3">Project Terms {project?('— '+project.name):''}</h4>
 <div className="table-responsive">
 <table className="table table-sm align-middle">
 <thead><tr><th>#</th><th className="text-end">%</th><th>Description</th><th>Status</th><th></th></tr></thead>
 <tbody>
 {terms.map((t,i)=>(
 <tr key={i}>
 <td>{i+1}</td>
 <td className="text-end" style={{width:120}}>
 <input type="number" min="0" max="100" step="0.01" className="form-control form-control-sm text-end"
 value={t.percentage} onChange={e=>upd(i,'percentage',e.target.value)} />
 </td>
 <td><input className="form-control form-control-sm" value={t.description} onChange={e=>upd(i,'description',e.target.value)} placeholder="e.g. UAT sign-off" /></td>
 <td style={{width:220}}>
 <select className="form-select form-select-sm" value={t.status_id||''} onChange={e=>upd(i,'status_id', e.target.value?Number(e.target.value):null)}>
 <option value="">--</option>
 {statuses.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}
 </select>
 </td>
 <td style={{width:90}}><button className="btn btn-sm btn-outline-danger" onClick={()=>del(i)}>Remove</button></td>
 </tr>
 ))}
 </tbody>
 <tfoot><tr><th>Total</th><th className="text-end">{total.toFixed(2)}%</th><th colSpan="3"></th></tr></tfoot>
 </table>
 </div>
 <div className="d-flex gap-2">
 <button className="btn btn-outline-secondary" onClick={addRow}>Add Row</button>
 <button className="btn btn-primary" onClick={save} disabled={!valid}>Save Terms</button>
 {msg && <div className="ms-2">{msg}</div>}
 </div>
 </div>
 </div>
 )
}
