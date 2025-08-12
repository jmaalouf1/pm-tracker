import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE || "http://104.197.102.89:8080",
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("pt_token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api;

