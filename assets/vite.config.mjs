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
    // https://vitejs.dev/guide/dep-pre-bundling#monorepos-and-linked-dependencies
    include: ["phoenix", "phoenix_html", "phoenix_live_view"],
  },
  build: {
    manifest: true,
    rollupOptions: {
      input: ["js/app.tsx", "css/app.css"],
    },
    outDir: "../priv/static",
    emptyOutDir: true,
  },
  // LV Colocated JS and Hooks
  // https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.ColocatedJS.html#module-internals
  resolve: {
    alias: [
      // Place more specific aliases before catch-alls to avoid shadowing
      { find: "@catalyst", replacement: fileURLToPath(new URL('./js/catalyst', import.meta.url)) },
      { find: "@", replacement: fileURLToPath(new URL('.', import.meta.url)) },
      { find: "phoenix-colocated", replacement: `${process.env.MIX_BUILD_PATH}/phoenix-colocated` },
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
