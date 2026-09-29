import { mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { zipSync } from 'fflate';

const entries = {};
async function collect(dir, prefix = '') {
  for (const entry of (await readdir(dir, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
    const name = `${prefix}${entry.name}`;
    if (entry.isDirectory()) await collect(`${dir}/${entry.name}`, `${name}/`);
    else if (entry.isFile()) entries[name] = [await readFile(`${dir}/${entry.name}`), { mtime: new Date(2020, 0, 1) }];
    else throw new Error(`Unexpected non-file in package: ${name}`);
  }
}
await collect('build/extension');
await mkdir('release', { recursive: true });
const filename = 'codedoodles-extension.zip';
const archive = zipSync(entries, { level: 9 });
await writeFile(`release/${filename}`, archive);
await writeFile('release/SHA256SUMS', `${createHash('sha256').update(archive).digest('hex')}  ${filename}\n`);
console.log(`Packaged release/${filename} (${archive.length} bytes)`);
