# from ~/projects/frontend
mkdir -p src/lib
cat > src/lib/api.js <<'JS'
export function getToken() {
  try { return localStorage.getItem('token') || '' } catch { return '' }
}
export function setToken(tok) {
  try { tok ? localStorage.setItem('token', tok) : localStorage.removeItem('token') } catch {}
}
export function authHeader() {
  const t = getToken()
  return t ? { Authorization: `Bearer ${t}` } : {}
}
export async function apiFetch(url, opts = {}) {
  const headers = { ...(opts.headers || {}), ...authHeader() }
  const res = await fetch(url, { ...opts, headers })
  return res
}
JS
