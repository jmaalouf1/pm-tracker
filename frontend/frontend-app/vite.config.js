// vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    proxy: {
      '/auth': 'http://127.0.0.1:8080',
      '/users': 'http://127.0.0.1:8080',
      '/projects': 'http://127.0.0.1:8080',
      '/customers': 'http://127.0.0.1:8080',
    }
  }
})

