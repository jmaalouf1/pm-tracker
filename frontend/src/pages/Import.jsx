// frontend/src/pages/Import.jsx
import React,{useState} from 'react'
import { apiFetch } from '../lib/api'

export default function ImportExcel(){
  const [file,setFile]=useState(null)
  const [busy,setBusy]=useState(false)
  const [result,setResult]=useState(null)
  const [err,setErr]=useState(null)

  const downloadTemplate=()=>window.open('/api/import/template.xlsx','_blank')

  async function onSubmit(e){
    e.preventDefault()
    if(!file) return
    setBusy(true); setErr(null); setResult(null)
    try{
      const fd=new FormData(); fd.append('file',file)
      const res=await apiFetch('/api/import/excel',{method:'POST',body:fd})
      const out=await res.json().catch(()=> ({}))
      if(!res.ok) throw new Error(out?.message||`Upload failed (${res.status})`)
      setResult(out)
    }catch(e){ setErr(e) }finally{ setBusy(false) }
  }

  return (
    <div className="container-page py-3">
      <h3 className="mb-3">Bulk Import</h3>
      <div className="card p-3">
        <p className="text-muted">
          Excel tabs: <b>Customers</b>, <b>Contacts</b>, <b>Projects</b>, <b>PaymentTerms</b>, optional <b>Lookups</b>.
        </p>
        <div className="d-flex gap-2 mb-3">
          <button className="btn btn-outline-secondary btn-sm" onClick={downloadTemplate}>Download template</button>
        </div>
        <form onSubmit={onSubmit} className="d-flex gap-2">
          <input type="file" className="form-control" accept=".xlsx" onChange={e=>setFile(e.target.files?.[0]||null)} />
          <button className="btn btn-primary" disabled={!file||busy}>{busy?'Importing…':'Import'}</button>
        </form>
        {err && <div className="alert alert-danger mt-3">{String(err.message||err)}</div>}
        {result && <pre className="mt-3 bg-light p-2 small" style={{whiteSpace:'pre-wrap'}}>{JSON.stringify(result,null,2)}</pre>}
      </div>
    </div>
  )
}
