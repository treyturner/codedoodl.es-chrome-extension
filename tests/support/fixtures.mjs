export const site = 'https://doodles.treyturner.info';
export const artwork = 'https://doodle.treyturner.info';
export const fixtures = [1, 2, 3].map(index => ({
  id: `test${index}`, index, slug: `artist/sketch${index}`, name: `Sketch ${index}`,
  author: index === 2 ? { name: 'Test Artist' } :
    { name: 'Test Artist', website: 'https://example.org', github: 'artist', twitter: 'artist' },
  description: index === 3 ? '<p>A long sketch description.</p>'.repeat(50) : 'A test sketch',
  tags: ['canvas'], instructions: 'Move your mouse',
  interaction: index === 2 ? { keyboard: true } : { mouse: true, keyboard: true, touch: true },
  colour_scheme: index === 2 ? 'light' : 'dark',
}));

export const artworkHTML = `<!doctype html>
<html data-keys="0" data-pointers="0"><head><title>Test sketch</title>
<style>body { margin: 0; overflow: hidden; } canvas { width: 100vw; height: 100vh; display: block; }</style>
</head><body><canvas width="100" height="100"></canvas><script>
document.querySelector('canvas').getContext('2d').fillRect(0, 0, 100, 100);
addEventListener('keydown', () => document.documentElement.dataset.keys++);
addEventListener('pointerdown', () => document.documentElement.dataset.pointers++);
</script></body></html>`;

export async function routeArtwork(context) {
  await context.route(`${artwork}/**`, route => route.request().url().endsWith('index.html') ?
    route.fulfill({ contentType: 'text/html', body: artworkHTML }) :
    route.fulfill({ contentType: 'image/svg+xml', body: '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>' }));
}

export async function checkArtworkInput(page) {
  // Wait for the application's focus transfer; do not focus the iframe in the test.
  await page.waitForFunction(() => document.activeElement === document.querySelector('[data-doodle-frame]'));
  const frame = page.frameLocator('[data-doodle-frame]');
  await page.keyboard.press('ArrowRight');
  await frame.locator('html[data-keys="1"]').waitFor();
  await frame.locator('canvas').click({ position: { x: 500, y: 400 } });
  await frame.locator('html[data-pointers="1"]').waitFor();
}
