import assert from 'node:assert/strict';
import { test } from 'node:test';
import { openExtension, loadFixture } from './support/extension.mjs';
import { artwork, artworkHTML, fixtures, checkArtworkInput } from './support/fixtures.mjs';

async function waitText(page, selector, text) {
  await page.waitForFunction(({ selector, text }) =>
    document.querySelector(selector).textContent.replaceAll('\u00a0', ' ').trim() === text,
  { selector, text });
}

async function openInfo(page, touch = false) {
  const button = page.locator('[data-show-info]');
  if (touch) await button.tap(); else await button.click();
  await page.waitForSelector('#page-doodle.show-info');
  // Wait for the sliding panel to finish before sending native scroll gestures.
  await page.waitForFunction(() => Math.abs(document.querySelector('[data-doodle-info]').getBoundingClientRect().left) < 1);
}

async function settleScroll(scroller) {
  await scroller.evaluate(el => new Promise(resolve => {
    let previous = el.scrollTop;
    let stableFrames = 0;
    const check = () => {
      stableFrames = el.scrollTop === previous ? stableFrames + 1 : 0;
      previous = el.scrollTop;
      if (stableFrames >= 6) resolve(); else requestAnimationFrame(check);
    };
    requestAnimationFrame(check);
  }));
}

test('colour schemes, optional metadata, hover animations and explicit playback', { timeout: 60000 }, async t => {
  const { page, base } = await openExtension(t);
  for (const fixture of fixtures.slice(0, 2)) {
    await loadFixture(page, base, fixture, false);
    assert.equal(await page.locator('#page-doodle').getAttribute('data-color-scheme'), fixture.colour_scheme);
    assert.equal(await page.locator('.logo__link [data-codetext-char]').first().evaluate(el => getComputedStyle(el).color),
      fixture.colour_scheme === 'light' ? 'rgb(17, 17, 17)' : 'rgb(255, 255, 255)');
    const expected = `show \`${fixture.author.name} \\ ${fixture.name}\``;
    await waitText(page, '[data-show-doodle-btn]', expected);
    await page.locator('[data-show-doodle-btn]').hover();
    await page.waitForFunction(expected => document.querySelector('[data-show-doodle-btn]').textContent.replaceAll('\u00a0', ' ') !== expected, expected);
    await page.mouse.move(600, 700);
    await waitText(page, '[data-show-doodle-btn]', expected);
    await page.locator('[data-show-doodle-btn]').click();
    await page.waitForSelector('[data-doodle-frame].show');
    await checkArtworkInput(page);
    await openInfo(page);
    assert.equal(await page.locator('.row-doodle-name .col-2').textContent(), fixture.name);
    assert.equal(await page.locator('[data-indicator="keyboard"]').getAttribute('disabled'), null);
    if (fixture.index === 2) {
      assert.equal(await page.locator('.row-author a').count(), 0);
      assert.equal(await page.locator('.row-interaction .col-2').textContent(), 'Keyboard');
    }
    await page.mouse.move(600, 700);
    await waitText(page, '[data-close-doodle]', 'close');
    await waitText(page, '.logo__link', 'codedoodl.es');
    await page.screenshot({ path: `test-results/ui-${fixture.colour_scheme}.png` });
    await page.keyboard.press('Escape');
    await page.waitForSelector('#page-doodle.show-info', { state: 'detached' });
    await waitText(page, '[data-show-info]', 'info');
  }
});

test('native information scrolling remains usable through resize and reopen', { timeout: 60000 }, async t => {
  const { page, base } = await openExtension(t);
  await loadFixture(page, base, fixtures[2]);
  await openInfo(page);
  for (const viewport of [{ width: 1280, height: 900 }, { width: 1280, height: 400 },
    { width: 750, height: 700 }, { width: 520, height: 650 }, { width: 1280, height: 900 }]) {
    await page.setViewportSize(viewport);
    await page.waitForFunction(({ width, height }) =>
      CD_CE.appView.dims.w === width && CD_CE.appView.dims.h === height, viewport);
    const selector = viewport.width <= 750 ? '[data-doodle-info]' : '.doodle-info-inner';
    await page.waitForFunction(({ selector, height }) => {
      const el = document.querySelector(selector);
      const rect = el.getBoundingClientRect();
      return el.tabIndex === 0 && el.scrollHeight > el.clientHeight && rect.height > 0 && rect.bottom <= height + 1;
    }, { selector, height: viewport.height });
    const scroller = page.locator(selector);
    await scroller.evaluate(el => { el.scrollTop = 0; });
    const box = await scroller.boundingBox();
    await page.mouse.move(box.x + box.width / 2, box.y + Math.min(80, box.height / 2));
    await page.mouse.wheel(0, 300);
    await page.waitForFunction(selector => document.querySelector(selector).scrollTop > 0, selector);
    await settleScroll(scroller);
    await scroller.focus();
    await page.keyboard.press('End');
    await page.waitForFunction(selector => {
      const el = document.querySelector(selector);
      return el.scrollTop + el.clientHeight >= el.scrollHeight - 2;
    }, selector);
    await settleScroll(scroller);
    const share = await page.locator('.row-share').boundingBox();
    assert.ok(share.y >= 0 && share.y + share.height <= viewport.height + 1, JSON.stringify(share));
    await page.keyboard.press('Home');
    await page.waitForFunction(selector => document.querySelector(selector).scrollTop === 0, selector);
  }
  await page.locator('[data-close-doodle]').click();
  await openInfo(page);
  assert.equal(await page.locator('.doodle-info-inner').evaluate(el => el.scrollTop), 0);
  await page.mouse.move(600, 700);
  await waitText(page, '[data-close-doodle]', 'close');
  await waitText(page, '.logo__link', 'codedoodl.es');
  await page.screenshot({ path: 'test-results/ui-long-info.png' });
});

test('artwork finishing its load does not steal focus from open information', { timeout: 20000 }, async t => {
  const { page, base, context } = await openExtension(t);
  let releaseArtwork;
  const gate = new Promise(resolve => { releaseArtwork = resolve; });
  t.after(releaseArtwork);
  await context.route(`${artwork}/**/index.html`, async route => {
    await gate;
    await route.fulfill({ contentType: 'text/html', body: artworkHTML });
  });
  await page.evaluate(async doodle => {
    await chrome.storage.local.set({ doodles: [doodle], lastUpdated: Date.now() });
    await chrome.storage.sync.set({ option_autoplay: true });
  }, fixtures[2]);
  await page.goto(`${base}/index.html`, { waitUntil: 'domcontentloaded' });
  await openInfo(page);
  await page.locator('.doodle-info-inner').focus();
  releaseArtwork();
  await page.waitForSelector('[data-doodle-frame].show');
  // Cross the application's 500 ms delayed-focus deadline.
  await page.waitForTimeout(650);
  assert.equal(await page.locator('.doodle-info-inner').evaluate(el => document.activeElement === el), true);
  await page.keyboard.press('Escape');
  await page.waitForSelector('#page-doodle.show-info', { state: 'detached' });
  await checkArtworkInput(page);
});

test('touch-capable desktop can play artwork and scroll information', { timeout: 60000 }, async t => {
  const { page, base, context } = await openExtension(t, { hasTouch: true });
  await loadFixture(page, base, fixtures[2], false);
  await page.locator('[data-show-doodle-btn]').tap();
  await page.waitForSelector('[data-doodle-frame].show');
  await page.frameLocator('[data-doodle-frame]').locator('canvas').tap({ position: { x: 500, y: 400 } });
  await page.frameLocator('[data-doodle-frame]').locator('html[data-pointers="1"]').waitFor();
  await openInfo(page, true);
  const client = await context.newCDPSession(page);
  for (const width of [1280, 600]) {
    await page.setViewportSize({ width, height: 900 });
    await page.waitForFunction(width => CD_CE.appView.dims.w === width, width);
    const selector = width > 750 ? '.doodle-info-inner' : '[data-doodle-info]';
    await page.waitForFunction(selector => document.querySelector(selector).tabIndex === 0, selector);
    const box = await page.locator(selector).boundingBox();
    const x = box.x + box.width / 2;
    const y = Math.min(box.y + box.height - 40, 800);
    await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] });
    for (let distance = 30; distance <= 180; distance += 30) {
      await client.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x, y: y - distance }] });
    }
    await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForFunction(selector => document.querySelector(selector).scrollTop > 0, selector);
    await settleScroll(page.locator(selector));
  }
  await client.detach();
  await page.locator('[data-close-doodle]').tap();
  await page.waitForSelector('#page-doodle.show-info', { state: 'detached' });
  await waitText(page, '[data-show-info]', 'info');
  await page.screenshot({ path: 'test-results/ui-touch.png' });
});
