import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { unzipSync, strFromU8 } from 'fflate';

test('release ZIP is complete, reproducible and independent of the Chrome Web Store', async () => {
  const archive = await readFile('release/codedoodles-extension.zip');
  const files = unzipSync(archive);
  const manifest = JSON.parse(strFromU8(files['manifest.json']));
  const pkg = JSON.parse(await readFile('package.json', 'utf8'));
  const notices = strFromU8(files['THIRD-PARTY-NOTICES.txt']);
  for (const name of ['jquery', 'underscore', 'backbone']) {
    assert.ok(notices.includes(`${name} ${pkg.dependencies[name]}`), `${name}: missing license notice`);
  }
  assert.equal(manifest.manifest_version, 3);
  assert.equal(manifest.update_url, undefined);
  assert.equal(manifest.background, undefined);
  assert.deepEqual(manifest.permissions, ['storage']);
  assert.deepEqual(manifest.host_permissions, ['https://doodles.treyturner.info/*']);
  assert.ok(!manifest.content_security_policy.extension_pages.includes('unsafe-eval'));
  for (const file of ['README.md', 'LICENSE', manifest.chrome_url_overrides.newtab, manifest.options_page, ...Object.values(manifest.icons)]) {
    assert.ok(files[file], `Missing manifest resource: ${file}`);
  }
  for (const [name, data] of Object.entries(files)) {
    assert.ok(!/node_modules|^src\/|^scripts\/|\.pem$|\.crx$|\.map$/.test(name), name);
    if (/\.html$/.test(name)) {
      const html = strFromU8(data);
      assert.ok(!html.includes('{{'), `${name}: unresolved build placeholder`);
      for (const match of html.matchAll(/(?:src|href)="\/?([^"#:]+)"/g)) {
        assert.ok(files[match[1]], `${name}: missing local resource ${match[1]}`);
      }
    }
    if (/\.(?:js|html|json)$/.test(name)) {
      assert.doesNotMatch(strFromU8(data), /https?:\/\/(?:[\w-]+\.)?codedoodl\.es(?:[\/"'])/);
      assert.doesNotMatch(strFromU8(data), /clients2\.google\.com\/service\/update2/);
      assert.doesNotMatch(strFromU8(data), /Modernizr|IScroll|TweenLite|DeepModel|JQMIGRATE/);
    }
  }
  const digest = createHash('sha256').update(archive).digest('hex');
  assert.equal(await readFile('release/SHA256SUMS', 'utf8'), `${digest}  codedoodles-extension.zip\n`);
  execFileSync(process.execPath, ['scripts/package.mjs']);
  assert.deepEqual(await readFile('release/codedoodles-extension.zip'), archive);
  assert.deepEqual((await readdir('release')).sort(), ['SHA256SUMS', 'codedoodles-extension.zip']);
});
