import { defineConfig } from "vite";
import ViteRails from "vite-plugin-rails";

import tailwindcss from "tailwindcss";
import tailwindcssNesting from "tailwindcss/nesting";
import autoprefixer from "autoprefixer";

import postCssImportGlob from "postcss-import-ext-glob";
import postCssImport from "postcss-import";

import renamePlugin from "./app/frontend/libs/postcss_rename_component";

export default defineConfig({
  clearScreen: false,
  build: {
    emptyOutDir: true,
    sourcemap: true,
    target: "es6",
  },
  server: {
    host: "0.0.0.0",
    port: 3036,
    hmr: {
      host: "localhost",
    },
  },
  plugins: [
    ViteRails({
      envVars: { RAILS_ENV: "development" },
      fullReload: {
        additionalPaths: [],
      },
    }),
  ],
  css: {
    postcss: {
      plugins: [
        postCssImportGlob,
        postCssImport,
        renamePlugin,
        tailwindcssNesting,
        tailwindcss,
        autoprefixer,
      ],
    },
  },
});
