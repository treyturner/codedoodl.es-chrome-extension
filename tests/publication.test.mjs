import assert from 'node:assert/strict';
import { test } from 'node:test';
import { openExtension } from './support/extension.mjs';
import { fixtures, site } from './support/fixtures.mjs';

test('unpublished artwork stays out of fresh caches, stale fallback, and older API responses', { timeout: 120000 }, async t => {
  const { page, context, base } = await openExtension(t);
  const unpublished = ['samsy/boobs', 'samsy/fury-ribbons'].map((slug, i) => ({
    ...fixtures[0], slug, id: ['xgp', 'ank'][i], index: [74, 73][i], viewed: false,
  }));
  const allowed = [{ ...fixtures[0], viewed: true }, { ...fixtures[1], viewed: false }];
  let calls = 0;
  let failApi = true;
  let apiDoodles = [...unpublished, ...allowed];
  const requests = [];
  context.on('request', request => requests.push(request.url()));
  await context.route(`${site}/api/doodles`, route => {
    calls++;
    return failApi ? route.fulfill({ status: 503, body: 'Unavailable' }) : route.fulfill({ json: { doodles: apiDoodles } });
  });
  const cache = () => page.evaluate(() => chrome.storage.local.get(['doodles', 'lastUpdated']));
  async function seed(doodles, lastUpdated) {
    await page.evaluate(data => chrome.storage.local.set(data), { doodles, lastUpdated });
    await page.goto(`${base}/index.html`);
  }
  async function loaded() {
    await page.waitForSelector('[data-doodle-frame].show');
    const saved = await cache();
    assert.deepEqual(saved.doodles.map(d => d.slug).sort(), allowed.map(d => d.slug).sort());
    assert.equal(saved.doodles.find(d => d.id === allowed[0].id).viewed, true, 'Retain viewed state');
    return saved;
  }

  const freshTime = Date.now();
  await seed([...unpublished, ...allowed], freshTime);
  assert.equal((await loaded()).lastUpdated, freshTime);
  assert.equal(calls, 0, 'A usable fresh cache needs no fetch');

  await seed([...unpublished, ...allowed], 1);
  assert.equal((await loaded()).lastUpdated, 1, 'Failed refresh does not renew stale data');
  assert.equal(calls, 1);

  failApi = false;
  await seed([...unpublished, ...allowed], 1);
  assert.ok((await loaded()).lastUpdated > 1);
  assert.equal(calls, 2, 'Older API responses are filtered too');

  failApi = true;
  await seed(unpublished, Date.now());
  await page.waitForSelector('[data-load-error]:not([hidden])');
  assert.deepEqual((await cache()).doodles, [], 'Even an unusable cache is purged');
  assert.equal(calls, 3, 'A fresh cache containing only unpublished artwork must fetch');

  failApi = false;
  apiDoodles = unpublished;
  await page.locator('[data-retry]').click();
  await page.waitForSelector('[data-load-error]:not([hidden])');
  assert.equal(calls, 4, 'An API with no published artwork offers retry');
  assert.deepEqual((await cache()).doodles, []);

  apiDoodles = allowed;
  await page.locator('[data-retry]').click();
  await page.waitForSelector('[data-doodle-frame].show');
  assert.equal(calls, 5);
  assert.deepEqual((await cache()).doodles.map(d => d.slug).sort(), allowed.map(d => d.slug).sort());
  assert.ok(!requests.some(url => /\/samsy\/(?:boobs|fury-ribbons)(?:\/|$)/.test(url)), 'Never request unpublished artwork or previews');
});
