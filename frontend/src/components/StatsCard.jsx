import React from 'react'
export default function StatsCard({title, value, sub}) {
  return (
    <div className="card p-3">
      <div className="text-muted small">{title}</div>
      <div className="fs-4 fw-bold">{value}</div>
      {sub ? <div className="text-muted small">{sub}</div> : null}
    </div>
  )
}
