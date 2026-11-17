import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'node:path';

export default defineConfig({
  plugins: [react()],
  server: { host: '0.0.0.0', port: 5173 },
  // duas páginas: o criador de personagens (index.html) e a floresta com aldeia (world.html)
  build: { rollupOptions: { input: { main: resolve(__dirname, 'index.html'), world: resolve(__dirname, 'world.html') } } },
});
