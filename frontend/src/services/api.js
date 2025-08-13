import axios from 'axios';
function computeBase() {
  const env = (import.meta.env.VITE_API_BASE_URL || '').trim();
  if (env) return env;
  const { protocol, hostname } = window.location;
  return `${protocol}//${hostname}:8080/api`;
}
const api = axios.create({ baseURL: computeBase(), timeout: 15000 });
api.interceptors.request.use(cfg => {
  const token = localStorage.getItem('accessToken');
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});
api.interceptors.response.use(r => r, err => {
  const msg = err?.response?.data?.error || err?.message || 'Request failed';
  return Promise.reject(new Error(msg));
});
export default api;
