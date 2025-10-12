import { defineConfig } from 'vite';
import { phoenixVitePlugin } from './phoenix-vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import { tanstackRouter } from '@tanstack/router-plugin/vite';
import react from '@vitejs/plugin-react';
import path from "path"

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
      input: ['src/app.js', 'css/app.css'],
    },
    outDir: '../priv/static',
    emptyOutDir: true,
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      "@components": path.resolve(__dirname, "./src/components"),
      "@catalyst": path.resolve(__dirname, "./src/catalyst"),
    },
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
      routesDirectory: 'src/routes',
      generatedRouteTree: 'src/routeTree.gen.ts',
      autoCodeSplitting: true,
    }),
    react(),
    tailwindcss(),
    phoenixVitePlugin({
      pattern: /\.(ex|heex)$/,
    }),
  ],
});
