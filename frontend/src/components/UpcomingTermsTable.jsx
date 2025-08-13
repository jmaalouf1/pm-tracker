import React from 'react'
export default function UpcomingTermsTable({rows}){
  return (
    <div className="card p-3">
      <div className="d-flex justify-content-between align-items-center mb-2">
        <h6 className="m-0">Upcoming payment terms</h6>
      </div>
      <div className="table-responsive">
        <table className="table align-middle">
          <thead>
            <tr>
              <th>Due</th><th>Project</th><th>Customer</th>
              <th className="text-end">% / Amount</th><th>Status</th>
            </tr>
          </thead>
          <tbody>
          {rows.map((r,i)=>(
            <tr key={i}>
              <td>{r.due_date?.slice(0,10)||''}</td>
              <td>{r.project_name}</td>
              <td>{r.customer_name||''}</td>
              <td className="text-end">{(r.percentage||0).toFixed(0)}% / {Number(r.amount||0).toLocaleString()}</td>
              <td>{r.status||'Planned'}</td>
            </tr>
          ))}
          {!rows.length && <tr><td colSpan="5" className="text-center text-muted py-4">No upcoming terms</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  )
}
