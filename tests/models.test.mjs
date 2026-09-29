import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createRequire } from 'node:module';
import Backbone from 'backbone';
import underscore from 'underscore';
import 'coffeescript/register.js';
import { fixtures } from './support/fixtures.mjs';

globalThis.Backbone = Backbone;
globalThis._ = underscore;
globalThis.window = {
  config: { hostname: 'chrome-extension://test', routes: { DOODLES: '_' } },
  CD_CE: { locale: { get: () => 'portfolio' } },
};
const require = createRequire(import.meta.url);
const Doodle = require('../src/coffee/models/doodle/DoodleModel.coffee');
const Doodles = require('../src/coffee/collections/doodles/DoodlesCollection.coffee');

test('catalogue models fill nested defaults without mutating input or sharing state', () => {
  const input = structuredClone(fixtures[1]);
  const original = structuredClone(input);
  const first = new Doodle(input);
  const second = new Doodle(input);
  assert.deepEqual(first.get('author'), { name: 'Test Artist', github: '', website: '', twitter: '' });
  assert.deepEqual(first.get('interaction'), { mouse: null, keyboard: true, touch: null });
  assert.equal(first.get('index_padded'), '02');
  assert.equal(first.get('indexHTML'), '<span class="index-char-zero">0</span><span class="index-char-nonzero">2</span>');
  assert.equal(first.get('url'), 'chrome-extension://test/_/artist/sketch2');
  assert.match(first.getAuthorHtml(), /Test Artist/);
  first.get('author').name = 'Changed';
  first.get('interaction').mouse = true;
  first.get('tags').push('changed');
  first.get('scrambled').name = 'changed';
  assert.equal(second.get('author').name, 'Test Artist');
  assert.equal(second.get('interaction').mouse, null);
  assert.deepEqual(second.get('tags'), ['canvas']);
  assert.notEqual(second.get('scrambled').name, 'changed');
  assert.deepEqual(input, original);
  const empty = new Doodle();
  const another = new Doodle();
  empty.get('tags').push('isolated');
  assert.deepEqual(another.get('tags'), []);
});

test('standard Backbone updates preserve change events, options and unrelated metadata', () => {
  const model = new Doodle(fixtures[0]);
  const author = structuredClone(model.get('author'));
  const events = [];
  model.on('change:viewed', (_model, value) => events.push(value));
  assert.equal(model.set('viewed', true), model);
  model.set({ viewed: false });
  model.set('viewed', true, { silent: true });
  assert.deepEqual(events, [true, false]);
  assert.equal(model.get('viewed'), true);
  assert.deepEqual(model.get('author'), author);
  assert.equal(model.hasChanged('viewed'), true);
});

test('serialized rotation survives reload and an exhausted catalogue still selects a sketch', () => {
  const first = new Doodles(fixtures);
  assert.equal(first.getNextDoodle().id, 'test1');
  const cached = JSON.parse(JSON.stringify(first));
  const reloaded = new Doodles(cached);
  assert.equal(reloaded.get('test1').get('viewed'), true);
  assert.equal(reloaded.getNextDoodle().id, 'test2');
  assert.equal(reloaded.getNextDoodle().id, 'test3');
  assert.ok(reloaded.models.includes(reloaded.getNextDoodle()));
  for (const model of reloaded.models) {
    const saved = cached.find(record => record.id === model.id);
    for (const field of ['id', 'slug', 'author', 'interaction', 'indexHTML']) {
      assert.deepEqual(model.get(field), saved[field], field);
    }
  }
});
