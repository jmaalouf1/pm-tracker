// frontend/src/pages/Home.jsx
import React, { useEffect, useState } from 'react'
import { apiFetch } from '../lib/api'

export default function Home(){
  const [summary,setSummary] = useState(null)
  const [upcoming,setUpcoming] = useState([])
  const [loading,setLoading] = useState(true)
  const [err,setErr] = useState(null)

  useEffect(()=>{
    let on=true;(async()=>{
      try{
        setLoading(true); setErr(null)
        const [s,u]=await Promise.all([
          apiFetch('/api/dashboard/summary'),
          apiFetch('/api/dashboard/terms/upcoming?limit=10')
        ])
        if(!on) return
        setSummary(s.ok?await s.json():{total_projects:0,pending:{cnt:0},overdue:{cnt:0}})
        setUpcoming(u.ok?await u.json():[])
      }catch(e){ on&&setErr(e) }finally{ on&&setLoading(false) }
    })(); return ()=>{on=false}
  },[])

  return (
    <div className="container-page py-3">
      <h3 className="mb-3">Overview</h3>
      {err && <div className="alert alert-warning">Couldn’t load dashboard data.</div>}

      <div className="row g-3">
        <div className="col-md-4"><div className="card p-3">
          <div className="text-muted small">Total projects</div>
          <div className="fs-3 fw-bold">{loading?'—':(summary?.total_projects??0)}</div>
        </div></div>
        <div className="col-md-4"><div className="card p-3">
          <div className="text-muted small">Pending terms</div>
          <div className="fs-3 fw-bold">{loading?'—':(summary?.pending?.cnt??0)}</div>
        </div></div>
        <div className="col-md-4"><div className="card p-3">
          <div className="text-muted small">Overdue terms</div>
          <div className="fs-3 fw-bold">{loading?'—':(summary?.overdue?.cnt??0)}</div>
        </div></div>
      </div>

      <div className="card p-3 mt-4">
        <h5 className="mb-2">Upcoming payment terms</h5>
        <div className="table-responsive">
          <table className="table align-middle">
            <thead><tr><th>Due</th><th>Project</th><th>Customer</th><th className="text-end">% / Amount</th><th>Status</th></tr></thead>
            <tbody>
              {loading ? (
                <tr><td colSpan="5" className="text-center text-muted">Loading…</td></tr>
              ) : upcoming.length ? upcoming.map((r,i)=>(
                <tr key={i}>
                  <td>{(r.due_date||'').slice(0,10)}</td>
                  <td>{r.project_name||''}</td>
                  <td>{r.customer_name||''}</td>
                  <td className="text-end">{(r.percentage??0)}% / {Number(r.amount||0).toLocaleString()}</td>
                  <td>{r.status||'Planned'}</td>
                </tr>
              )) : (
                <tr><td colSpan="5" className="text-center text-muted">No upcoming terms</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
