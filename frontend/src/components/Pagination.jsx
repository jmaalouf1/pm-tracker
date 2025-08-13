import React from 'react'
export default function Pagination({page, pages, total, pageSize, setPage, setPageSize}){
  const canPrev = page > 1
  const canNext = page < pages
  return (
    <div className="d-flex justify-content-between align-items-center mt-3">
      <div className="d-flex align-items-center gap-2">
        <span className="text-muted">Rows:</span>
        <select className="form-select form-select-sm" style={{width:'auto'}}
                value={pageSize} onChange={e=>setPageSize(Number(e.target.value))}>
          {[10,20,50,100].map(n => <option key={n} value={n}>{n}</option>)}
        </select>
        <span className="text-muted">Total: {total}</span>
      </div>
      <div className="btn-group">
        <button className="btn btn-sm btn-outline-secondary" disabled={!canPrev} onClick={()=>setPage(1)}>First</button>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canPrev} onClick={()=>setPage(page-1)}>Prev</button>
        <span className="btn btn-sm btn-light disabled">{page} / {pages}</span>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canNext} onClick={()=>setPage(page+1)}>Next</button>
        <button className="btn btn-sm btn-outline-secondary" disabled={!canNext} onClick={()=>setPage(pages)}>Last</button>
      </div>
    </div>
  )
}
