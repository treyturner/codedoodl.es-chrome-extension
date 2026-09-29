import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, mkdtemp, rm } from 'node:fs/promises';
import { resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { chromium } from 'playwright';
import { fixtures, site, routeArtwork } from './fixtures.mjs';

export async function openExtension(t, { hasTouch = false } = {}) {
  const extensionPath = resolve('build/extension');
  const extensionId = [...createHash('sha256').update(extensionPath).digest('hex').slice(0, 32)]
    .map(char => String.fromCharCode(97 + parseInt(char, 16))).join('');
  const base = `chrome-extension://${extensionId}`;
  const profile = await mkdtemp(`${tmpdir()}/codedoodles-ui-`);
  const context = await chromium.launchPersistentContext(profile, {
    channel: 'chromium', headless: true, hasTouch, viewport: { width: 1280, height: 900 },
    args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`],
  });
  context.setDefaultTimeout(10000);
  await mkdir('test-results', { recursive: true });
  await context.tracing.start({ screenshots: true, snapshots: true });
  const errors = [];
  context.on('page', page => {
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (/Content Security Policy|unsafe-eval|JQMIGRATE:/.test(message.text())) errors.push(message.text());
    });
  });
  t.after(async () => {
    await context.tracing.stop({ path: `test-results/${t.name.replaceAll(/[^a-z0-9]+/gi, '-').toLowerCase()}-trace.zip` });
    await context.close();
    await rm(profile, { recursive: true, force: true });
    assert.deepEqual(errors, [], 'extension errors');
  });
  await context.route(`${site}/api/doodles`, route => route.fulfill({ json: { doodles: fixtures } }));
  await routeArtwork(context);
  const page = await context.newPage();
  await page.goto(`${base}/options.html`);
  return { page, context, base };
}

export async function loadFixture(page, base, doodle, autoplay = true) {
  await page.evaluate(async ({ doodle, autoplay }) => {
    await chrome.storage.local.set({ doodles: [doodle], lastUpdated: Date.now() });
    await chrome.storage.sync.set({ option_autoplay: autoplay, option_show_apps_btn: true });
  }, { doodle, autoplay });
  await page.goto(`${base}/index.html`);
  await page.waitForSelector(autoplay ? '[data-doodle-frame].show' : '[data-show-doodle-btn-pane].show');
}
