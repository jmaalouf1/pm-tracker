import React, {useState} from 'react'
export default function ImportExcel(){
  const [file,setFile] = useState(null)
  const [busy,setBusy] = useState(false)
  const [result,setResult] = useState(null)
  function dlTemplate(){ window.open('/api/import/template.xlsx','_blank') }
  async function submit(e){
    e.preventDefault()
    if(!file) return
    setBusy(true); setResult(null)
    const fd = new FormData()
    fd.append('file', file)
    const r = await fetch('/api/import/excel',{method:'POST', body:fd})
    const out = await r.json()
    setBusy(false); setResult(out)
  }
  return (
    <div className="card p-3">
      <h5>Bulk Import</h5>
      <p className="text-muted">Use the Excel template (Customers, Contacts, Projects, PaymentTerms, Lookups(Optional)).</p>
      <div className="d-flex gap-2 mb-2">
        <button className="btn btn-outline-secondary btn-sm" onClick={dlTemplate}>Download template</button>
      </div>
      <form onSubmit={submit} className="d-flex gap-2 align-items-center">
        <input type="file" className="form-control" accept=".xlsx" onChange={e=>setFile(e.target.files?.[0]||null)} />
        <button className="btn btn-primary" disabled={!file||busy}>{busy?'Importing...':'Import'}</button>
      </form>
      {result && <pre className="mt-3 bg-light p-2 small" style={{whiteSpace:'pre-wrap'}}>{JSON.stringify(result,null,2)}</pre>}
    </div>
  )
}
