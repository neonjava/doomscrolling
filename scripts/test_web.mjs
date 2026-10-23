import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const web = resolve(root, 'web');

console.log('Testing Doomscrolling website static files...');

const requiredFiles = [
  'index.html',
  'open-source.html',
  'privacy.html',
  'styles.css',
  'app.js',
  'theme.js',
  'assets/logo.svg',
  'assets/app-dark.png',
  'assets/app-light.png',
  'Doomscrolling-v0.1.0.apk',
];

for (const file of requiredFiles) {
  const fullPath = resolve(web, file);
  if (!existsSync(fullPath)) {
    throw new Error(`Missing required file: web/${file}`);
  }
}

// Verify index.html links
const indexHtml = readFileSync(resolve(web, 'index.html'), 'utf8');
if (!indexHtml.includes('/download')) throw new Error('index.html missing download link');
if (!indexHtml.includes('/open-source')) throw new Error('index.html missing open-source link');
if (!indexHtml.includes('Doomscrolling')) throw new Error('index.html missing title/brand');

console.log('✓ All required website files and routes are present and valid.');
