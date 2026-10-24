import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {existsSync} from 'node:fs';
import {mkdir, readFile} from 'node:fs/promises';
import {chromium} from '@playwright/test';

const port = 4173;
const base = `http://127.0.0.1:${port}`;
const server = spawn('python3', ['scripts/serve_web.py', String(port)], {stdio: ['ignore', 'pipe', 'pipe']});
let browser;
try {
  for (let n = 0; n < 80; n++) {
    try { if ((await fetch(base)).ok) break; } catch {}
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  assert((await fetch(base)).ok, 'Flutter preview server must start');
  const config = JSON.parse(await readFile('vercel.json', 'utf8'));
  const download = await fetch(`${base}/download`, {redirect: 'manual'});
  assert.equal(download.status, 307);
  assert.equal(download.headers.get('location'), config.redirects.find(r => r.source === '/download').destination);
  const apk = await fetch(`${base}${download.headers.get('location')}`);
  assert(apk.ok, 'APK download must resolve');
  assert(Number(apk.headers.get('content-length')) > 1000000, 'Download must be an APK, not the app shell');
  const magic = new Uint8Array(await apk.arrayBuffer()).slice(0, 2);
  assert.deepEqual([...magic], [80, 75], 'APK is a ZIP archive');
  const executablePath = process.env.CHROMIUM_PATH || (existsSync('/usr/local/bin/chromium') ? '/usr/local/bin/chromium' : (existsSync('/usr/bin/chromium') ? '/usr/bin/chromium' : undefined));
  browser = await chromium.launch({headless: true, ...(executablePath ? {executablePath} : {}), args: ['--no-sandbox']});
  await mkdir('artifacts/web', {recursive:true});
  for (const [name, width, height] of [['desktop', 1440, 1000], ['mobile', 390, 844]]) {
    const context = await browser.newContext({viewport:{width, height}, colorScheme:'light'});
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => {
      console.error('PAGEERROR:', error);
      errors.push(error.stack || error.message);
    });
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.error('CONSOLE ERROR:', msg.text(), msg.location());
        errors.push(msg.text());
      }
    });
    await page.goto(base);
    await page.getByRole('button', {name:'Download for Android', exact:true}).waitFor({timeout:60000});
    await page.screenshot({path:`artifacts/web/${name}-light.png`});
    if (name === 'desktop') await page.getByText('Dark', {exact:true}).click();
    else {
      await page.getByRole('button', {name:'Appearance and navigation'}).click();
      await page.getByRole('menuitem', {name:'Dark theme'}).click();
    }
    await page.waitForTimeout(350);
    assert.equal(await page.evaluate(() => localStorage.getItem('doomscrolling-theme')), 'dark');
    await page.screenshot({path:`artifacts/web/${name}-dark.png`});
    await page.reload();
    await page.getByRole('button', {name:'Download for Android', exact:true}).waitFor();
    assert.equal(await page.evaluate(() => localStorage.getItem('doomscrolling-theme')), 'dark');
    const reminder = page.getByRole('button', {name:'Try the reminder', exact:true});
    // Flutter paints into a canvas: scroll its viewport, not just the semantics DOM.
    await page.mouse.move(width / 2, height / 2);
    for (let attempt = 0; attempt < 25; attempt++) {
      const bounds = await reminder.boundingBox();
      if (bounds && bounds.y >= 150 && bounds.y + bounds.height < height - 100) break;
      await page.mouse.wheel(0, 200);
      await page.waitForTimeout(100);
    }
    await reminder.click();
    await page.screenshot({path:`artifacts/web/${name}-reminder.png`});
    await page.getByText('You are doom scrolling', {exact:true}).first().waitFor({timeout:5000});
    await page.getByText('You are doom scrolling', {exact:true}).first().waitFor({state:'hidden',timeout:5000});
    for (const [path, title] of [['/open-source','Open source.\nOn your side.'], ['/privacy','Your screen stays\non your phone.']]) {
      await page.goto(`${base}${path}`);
      await page.getByText(title, {exact:true}).waitFor({timeout:30000});
      await page.reload();
      await page.getByText(title, {exact:true}).waitFor({timeout:30000});
    }
    assert.deepEqual(errors, [], `${name}: no JavaScript, rendering, or CSP errors`);
    await context.close();
    console.log(`PASS ${name}: render, theme persistence, reminder, deep links, reloads`);
  }
  console.log('PASS download: redirect resolves to an actual APK');
} finally {
  await browser?.close();
  server.kill('SIGTERM');
}
