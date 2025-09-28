import { defineConfig } from 'vite';
import { fileURLToPath } from 'node:url';
import { phoenixVitePlugin } from './phoenix-vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import { tanstackRouter } from '@tanstack/router-plugin/vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
    cors: { origin: 'http://localhost:4000' },
  },
  // optimizeDeps: {
  //   include: ['react', 'react-dom'],
  // },
  build: {
    manifest: true,
    rollupOptions: {
      input: ['js/app.js', 'css/app.css'],
    },
    outDir: '../priv/static',
    emptyOutDir: true,
  },
  resolve: {
    alias: [
      {
        find: '@catalyst',
        replacement: fileURLToPath(new URL('./js/catalyst', import.meta.url)),
      },
      { find: '@', replacement: fileURLToPath(new URL('.', import.meta.url)) },
    ],
    // Ensure only a single React instance is bundled to avoid
    dedupe: [
      'react',
      'react-dom',
      'react/jsx-runtime',
      'react/jsx-dev-runtime',
    ],
  },
  plugins: [
    tanstackRouter({
      target: 'react',
      autoCodeSplitting: true,
    }),
    react(),
    tailwindcss(),
    phoenixVitePlugin({
      pattern: /\.(ex|heex)$/,
    }),
  ],
});
