import React, {useEffect, useState} from 'react'
export default function Home(){
  const [summary,setSummary] = useState(null)
  const [upcoming,setUpcoming] = useState([])
  useEffect(()=>{
    fetch('/api/dashboard/summary').then(r=>r.json()).then(setSummary).catch(()=>{})
    fetch('/api/dashboard/terms/upcoming?limit=10').then(r=>r.json()).then(setUpcoming).catch(()=>{})
  },[])
  return (
    <div className="d-flex flex-column gap-3">
      <div className="row g-3">
        <div className="col-sm-4"><div className="card p-3"><div className="text-muted small">Total projects</div><div className="fs-4 fw-bold">{summary?.total_projects||0}</div></div></div>
        <div className="col-sm-4"><div className="card p-3"><div className="text-muted small">Pending terms</div><div className="fs-4 fw-bold">{summary?.pending?.cnt||0}</div></div></div>
        <div className="col-sm-4"><div className="card p-3"><div className="text-muted small">Overdue terms</div><div className="fs-4 fw-bold">{summary?.overdue?.cnt||0}</div></div></div>
      </div>
      <div className="card p-3">
        <h6 className="mb-2">Upcoming payment terms</h6>
        <div className="table-responsive">
          <table className="table align-middle">
            <thead><tr><th>Due</th><th>Project</th><th>Customer</th><th className="text-end">% / Amount</th><th>Status</th></tr></thead>
            <tbody>
              {upcoming.map((r,i)=>(
                <tr key={i}>
                  <td>{r.due_date?.slice(0,10)||''}</td>
                  <td>{r.project_name}</td>
                  <td>{r.customer_name||''}</td>
                  <td className="text-end">{(r.percentage||0).toFixed(0)}% / {Number(r.amount||0).toLocaleString()}</td>
                  <td>{r.status||'Planned'}</td>
                </tr>
              ))}
              {!upcoming.length && <tr><td colSpan="5" className="text-center text-muted py-4">No upcoming terms</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
