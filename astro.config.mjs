// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';

import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://eik-it.github.io',
  base: '/vigrestadmaskin.no-site',

  vite: {
    plugins: [tailwindcss()]
  },

  integrations: [sitemap()]
});
