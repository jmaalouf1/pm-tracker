import React from 'react'
import { Search } from 'lucide-react'

export default function SearchInput({value, onChange, placeholder, width=600}) {
  return (
    <div style={{position:'relative', maxWidth:width, minWidth:320, width:'100%'}}>
      <Search size={16} style={{position:'absolute', left:10, top:'50%', transform:'translateY(-50%)', opacity:.55}} />
      <input
        className="form-control"
        style={{paddingLeft:36}}
        value={value}
        onChange={(e)=>onChange(e.target.value)}
        placeholder={placeholder||'Search'}
      />
    </div>
  )
}
