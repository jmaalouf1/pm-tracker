// src/context/AuthContext.jsx
import { createContext, useContext, useEffect, useMemo, useState } from "react";
import axios from "axios";

const AuthCtx = createContext(null);

/**
 * Use relative base ('') during development so Vite proxy handles /auth, /users, etc.
 * If you prefer an absolute URL, set VITE_API_BASE to "http://104.197.102.89:8080"
 * in a .env file and restart Vite.
 */
const API_BASE = (import.meta.env.VITE_API_BASE ?? "").replace(/\/$/, "");

function decodeJwt(token) {
  try {
    const payload = token.split(".")[1];
    return JSON.parse(atob(payload));
  } catch {
    return null;
  }
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [ready, setReady] = useState(false);

  // axios instance with baseURL + auth header
  const api = useMemo(() => {
    const instance = axios.create({ baseURL: API_BASE || "/" });
    instance.interceptors.request.use((config) => {
      const t = localStorage.getItem("token");
      if (t) config.headers.Authorization = `Bearer ${t}`;
      return config;
    });
    return instance;
  }, [API_BASE]);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (token) {
      const payload = decodeJwt(token);
      if (payload?.exp && payload.exp * 1000 > Date.now()) {
        setUser({
          username: payload.username,
          role: payload.role,
          id: payload.id,
          token,
        });
      } else {
        localStorage.removeItem("token");
      }
    }
    setReady(true);
  }, []);

  async function signin({ username, password }) {
    // IMPORTANT: use the api instance, not axios directly,
    // and use a relative path so the Vite proxy can kick in.
    const { data } = await api.post("/auth/login", { username, password });
    const token = data?.token;
    if (!token) throw new Error("No token returned");
    localStorage.setItem("token", token);

    const payload = decodeJwt(token);
    if (!payload) throw new Error("Invalid token");
    setUser({
      username: payload.username,
      role: payload.role,
      id: payload.id,
      token,
    });
    return true;
  }

  function signout() {
    localStorage.removeItem("token");
    setUser(null);
  }

  const value = { user, ready, signin, signout, api, API_BASE };
  return <AuthCtx.Provider value={value}>{children}</AuthCtx.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthCtx);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}

