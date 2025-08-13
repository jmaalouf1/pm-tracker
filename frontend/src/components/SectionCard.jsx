import React from 'react'
export default function SectionCard({title, extra, children}) {
  return (
    <div className="card p-3 mb-3">
      {(title || extra) && (
        <div className="d-flex justify-content-between align-items-center mb-2">
          <h5 className="m-0">{title}</h5>
          {extra}
        </div>
      )}
      {children}
    </div>
  )
}
