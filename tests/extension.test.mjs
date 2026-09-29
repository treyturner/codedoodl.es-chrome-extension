import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { mkdtemp, rm, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { chromium } from 'playwright';
import { site, artwork, fixtures, routeArtwork, checkArtworkInput } from './support/fixtures.mjs';

const live = process.env.LIVE_TEST === '1';

test(live ? 'installed extension against the hosted instances' : 'installed extension: new tab, controls, preferences and cache recovery', { timeout: 120000 }, async t => {
  const extensionPath = resolve('build/extension');
  const extensionId = [...createHash('sha256').update(extensionPath).digest('hex').slice(0, 32)]
    .map(char => String.fromCharCode('a'.charCodeAt(0) + parseInt(char, 16))).join('');
  const base = `chrome-extension://${extensionId}`;
  const profile = await mkdtemp(`${tmpdir()}/codedoodles-extension-`);
  const context = await chromium.launchPersistentContext(profile, {
    channel: 'chromium', headless: true, viewport: { width: 1280, height: 900 },
    args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`],
  });
  await mkdir('test-results', { recursive: true });
  await context.tracing.start({ screenshots: true, snapshots: true });
  t.after(async () => {
    await context.tracing.stop({ path: `test-results/${live ? 'live' : 'fixture'}-trace.zip` });
    await context.close();
    await rm(profile, { recursive: true, force: true });
  });
  const pageErrors = [];
  const cspErrors = [];
  const migrationWarnings = [];
  const oldHostRequests = [];
  context.on('page', page => {
    page.on('pageerror', error => pageErrors.push(error.message));
    page.on('console', message => {
      if (/Content Security Policy|unsafe-eval/i.test(message.text())) cspErrors.push(message.text());
      if (/JQMIGRATE:/.test(message.text()) && !/Migrate is installed/.test(message.text())) migrationWarnings.push(message.text());
    });
  });
  context.on('request', request => {
    if (/^https?:\/\/(?:[^/]+\.)?codedoodl\.es(?:\/|$)/.test(request.url())) oldHostRequests.push(request.url());
  });
  let apiCalls = 0;
  let failApi = false;
  let malformedApi = false;
  if (!live) {
    await context.route(`${site}/api/doodles`, route => {
      apiCalls++;
      return failApi ? route.fulfill({ status: 503, body: 'Unavailable' }) :
        route.fulfill({ json: malformedApi ? { doodles: [] } : { doodles: fixtures } });
    });
    await routeArtwork(context);
  }
  const page = await context.newPage();
  await page.goto(`${base}/index.html`);
  await page.waitForSelector('[data-doodle-frame].show');
  const firstSrc = await page.locator('[data-doodle-frame]').getAttribute('src');
  assert.ok(firstSrc.startsWith(`${artwork}/`), firstSrc);
  await page.frameLocator('[data-doodle-frame]').locator('canvas').first().waitFor();
  if (!live) await checkArtworkInput(page);
  await page.screenshot({ path: `test-results/${live ? 'live' : 'fixture'}-newtab.png` });
  assert.equal(await page.locator('.logo__link').getAttribute('href'), site);
  await page.locator('[data-show-info]').click();
  await page.waitForSelector('#page-doodle.show-info');
  const shareUrl = await page.locator('.row-share a[target="_blank"]').getAttribute('href');
  assert.ok(shareUrl.startsWith(`${site}/`));
  await page.locator('[data-close-doodle]').click();
  await page.waitForSelector('#page-doodle.show-info', { state: 'detached' });
  let frameLoads = 0;
  page.on('framenavigated', frame => { if (frame.url() === firstSrc) frameLoads++; });
  await page.locator('[data-doodle-refresh]').click();
  await page.waitForFunction(() => document.querySelector('[data-doodle-frame]').classList.contains('show'));
  assert.ok(frameLoads > 0, 'refresh reloads the sketch');
  if (!live) await checkArtworkInput(page);
  const fetchedAt = await page.evaluate(async () => (await chrome.storage.local.get('lastUpdated')).lastUpdated);
  await page.locator('[data-doodle-random]').click();
  await page.waitForSelector('[data-doodle-frame].show');
  assert.notEqual(await page.locator('[data-doodle-frame]').getAttribute('src'), firstSrc);
  assert.equal(await page.evaluate(async () => (await chrome.storage.local.get('lastUpdated')).lastUpdated), fetchedAt);
  if (!live) assert.equal(apiCalls, 1, 'a fresh cache avoids another API request');

  const options = await context.newPage();
  await options.goto(`${base}/options.html`);
  await options.locator('#option_autoplay').uncheck();
  await options.locator('#option_show_apps_btn').check();
  await options.waitForFunction(async () => (await chrome.storage.sync.get('option_autoplay')).option_autoplay === false);
  await options.reload();
  assert.equal(await options.locator('#option_autoplay').isChecked(), false);
  await options.waitForFunction(() => document.querySelector('#option_show_apps_btn').checked);
  // Visit the real Chrome new-tab URL to exercise the manifest override.
  const tab = await context.newPage();
  await tab.goto('chrome://newtab/');
  await tab.waitForSelector('[data-show-doodle-btn-pane].show');
  assert.equal(await tab.locator('[data-doodle-frame]').getAttribute('src'), '');
  assert.equal(await tab.locator('.show-apps-btn').count(), 1);
  await tab.locator('[data-show-doodle-btn]').click();
  await tab.waitForSelector('[data-doodle-frame].show');
  if (!live) await checkArtworkInput(tab);
  await tab.close();
  await options.close();
  if (!live) {
    // Preferences can exist before the first catalogue fetch.
    await page.evaluate(() => chrome.storage.local.clear());
    await page.reload();
    await page.waitForSelector('[data-show-doodle-btn-pane].show');
    assert.equal(apiCalls, 2);
    // A failed refresh uses stale data without making its fetch timestamp newer.
    await page.evaluate(() => chrome.storage.local.set({ lastUpdated: 1 }));
    failApi = true;
    await page.reload();
    await page.waitForSelector('[data-show-doodle-btn-pane].show');
    assert.equal(await page.evaluate(async () => (await chrome.storage.local.get('lastUpdated')).lastUpdated), 1);
    // A first-time network failure is recoverable, not an endless blank new tab.
    await page.evaluate(() => chrome.storage.local.clear());
    await page.reload();
    await page.waitForSelector('[data-load-error]:not([hidden])');
    failApi = false;
    malformedApi = true;
    await page.locator('[data-retry]').click();
    await page.waitForSelector('[data-load-error]:not([hidden])');
    malformedApi = false;
    await page.locator('[data-retry]').click();
    await page.waitForSelector('[data-show-doodle-btn-pane].show');
  }
  await mkdir('test-results', { recursive: true });
  await page.screenshot({ path: 'test-results/extension.png' });
  assert.deepEqual(oldHostRequests, []);
  assert.deepEqual(cspErrors, []);
  assert.deepEqual(pageErrors, []);
  assert.deepEqual(migrationWarnings, []);
});
