import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { build } from 'esbuild';
import coffee from 'coffeescript';
import * as sass from 'sass';
import { parseStringPromise } from 'xml2js';
import underscore from 'underscore';

const pkg = JSON.parse(await readFile('package.json', 'utf8'));
const out = 'build/extension';
await rm(out, { recursive: true, force: true });
await cp('src/public', out, { recursive: true });
await cp('LICENSE', `${out}/LICENSE`);
await cp('README.md', `${out}/README.md`);
await mkdir(`${out}/css`, { recursive: true });
await mkdir(`${out}/js/vendor`, { recursive: true });

await build({
  entryPoints: ['src/coffee/Main.coffee'],
  outfile: `${out}/js/main.js`,
  bundle: true,
  minify: true,
  target: 'chrome120',
  drop: ['console'],
  resolveExtensions: ['.coffee', '.js'],
  plugins: [{
    name: 'coffee',
    setup(builder) {
      builder.onLoad({ filter: /\.coffee$/ }, async ({ path }) => ({
        contents: coffee.compile(await readFile(path, 'utf8'), { bare: true, filename: path }),
        loader: 'js',
      }));
    },
  }],
});

await build({
  entryPoints: ['src/js/vendor.js'],
  bundle: true,
  outfile: `${out}/js/vendor/v.js`,
  format: 'iife',
  target: 'chrome120',
  minify: true,
  legalComments: 'inline',
});
const notices = await Promise.all(['jquery', 'underscore', 'backbone'].map(async name =>
  `${name} ${pkg.dependencies[name]}\n\n${await readFile(`node_modules/${name}/${name === 'jquery' ? 'LICENSE.txt' : 'LICENSE'}`, 'utf8')}`));
await writeFile(`${out}/THIRD-PARTY-NOTICES.txt`, notices.join('\n\n---\n\n'));
const css = sass.compile('src/sass/main.scss', {
  style: 'compressed',
  // Keep the original Sass layout; migration of its syntax is independent of MV3.
  silenceDeprecations: ['import', 'global-builtin', 'slash-div', 'color-functions', 'if-function'],
});
await writeFile(`${out}/css/main.css`, css.css);

// MV3 forbids runtime template compilation (eval/new Function).
const { templates } = await parseStringPromise(await readFile('src/data/templates.xml', 'utf8'));
const compiled = templates.template.map(template =>
  `${JSON.stringify(template.$.id)}: ${underscore.template(template._.trim()).source}`);
await writeFile(`${out}/data/templates.js`, `window._TEMPLATES = {\n${compiled.join(',\n')}\n};\n`);
const html = (await readFile('src/html/index.html', 'utf8')).replace(/{{\s*([^{}]+?)\s*}}/g, '$1');
await writeFile(`${out}/index.html`, html);
console.log(`Built ${out}`);
