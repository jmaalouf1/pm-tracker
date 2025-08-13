import React from 'react'
export default function SearchBox({value, onChange, placeholder="Search"}){
 return (
 <div className="input-icon w-100">
 
 <input className="form-control" value={value} onChange={e=>onChange(e.target.value)} placeholder={placeholder} />
 </div>
 )
}
