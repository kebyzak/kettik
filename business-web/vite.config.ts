import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Served by Caddy under /business/ next to the API, so the API is same-origin.
export default defineConfig({
  base: '/business/',
  plugins: [react()],
  server: {
    proxy: { '/auth': 'http://localhost:8080', '/biz': 'http://localhost:8080' },
  },
})
