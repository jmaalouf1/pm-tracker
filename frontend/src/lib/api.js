// frontend/src/lib/api.js

// Build a base like http://<host>:8080/api unless VITE_API_BASE is set
function cleanJoin(base, path) {
  if (!base.endsWith('/')) base += '/'
  if (path.startsWith('/')) path = path.slice(1)
  return base + path
}

export const API_BASE =
  (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_API_BASE)
    ? import.meta.env.VITE_API_BASE.replace(/\/+$/, '')
    : `${window.location.protocol}//${window.location.hostname}:8080/api`

export function apiUrl(path = '/') {
  return cleanJoin(API_BASE, path)
}

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

// Always call the backend at API_BASE
export async function apiFetch(path, opts = {}) {
  const url = path.startsWith('http') ? path : apiUrl(path)
  const headers = { ...(opts.headers || {}), ...authHeader() }
  return fetch(url, { ...opts, headers })
}
