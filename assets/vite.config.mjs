import { defineConfig } from 'vite'
import { fileURLToPath } from 'node:url'
import { phoenixVitePlugin } from 'phoenix_vite'
import tailwindcss from "@tailwindcss/vite";
import preact from '@preact/preset-vite';

export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
    cors: { origin: "http://localhost:4000" },
  },
  optimizeDeps: {
    include: [],
  },
  build: {
    manifest: true,
    rollupOptions: {
      input: ["js/app.tsx", "css/app.css"],
    },
    outDir: "../priv/static",
    emptyOutDir: true,
  },
  resolve: {
    alias: [
      { find: '@catalyst', replacement: fileURLToPath(new URL('./js/catalyst', import.meta.url)) },
      { find: '@', replacement: fileURLToPath(new URL('.', import.meta.url)) },
      { find: 'react', replacement: 'preact/compat' },
      { find: 'react-dom', replacement: 'preact/compat' },
      { find: 'react-dom/test-utils', replacement: 'preact/test-utils' },
    ],
  },
  plugins: [
    preact(),
    tailwindcss(),
    phoenixVitePlugin({
      pattern: /\.(ex|heex)$/
    })
  ]
});
