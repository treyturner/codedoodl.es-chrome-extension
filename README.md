# codedoodl.es Chrome extension

A new-tab extension for [the restored codedoodl.es site](https://doodles.treyturner.info),
using sketches from `https://doodle.treyturner.info`. The original artwork, interface,
random/refresh controls, information panel, and autoplay preference are retained.

This fork is distributed **only through GitHub Releases**. It has no Chrome Web Store
publisher, store credentials, store update URL, or packed `.crx`. It uses Manifest V3
for current desktop Chrome, including touch-capable computers. Sketches still need an internet connection; the extension
caches catalogue metadata, not the artwork.

## Install or update

1. Download `codedoodles-extension.zip` from
   [the latest GitHub release](https://github.com/treyturner/codedoodl.es-chrome-extension/releases/latest).
   Choose this asset, not GitHub's automatically generated source archive.
2. Extract it into a permanent folder. `manifest.json` is at the archive root.
3. Open `chrome://extensions`, enable **Developer mode**, click **Load unpacked**,
   and select that folder.
4. Open a new tab. Accept Chrome's new-tab change prompt if shown. Disable any
   competing new-tab extension if Chrome continues showing another page.

These are Chrome's [unpacked installation steps](https://developer.chrome.com/docs/extensions/get-started/tutorial/hello-world#load-unpacked).
The extension options are available on its card in `chrome://extensions`.

Updates are manual: extract a newer release into the **same folder**, replacing the
old files, click **Reload** on the extension's card, and open a fresh tab. Keep the
folder in place while the extension is installed. Each release includes `SHA256SUMS`
to verify the downloaded ZIP; the release tag and notes identify its exact commit.

## Build and test locally

Use the Node version in `.node-version` (24.21.0, with npm 11.19.0):

```sh
npm ci
npm run package
```

Load `build/extension/` directly as an unpacked extension, or distribute
`release/codedoodles-extension.zip`. Nothing under `build/` or `release/` is committed.

```sh
npx playwright install chromium
npm test
npm run test:live
```

`npm test` builds and packages the extension, verifies the archive and checksum,
and installs it into Playwright's Chromium with the real extension APIs and Manifest
V3 policy. It exercises the new-tab override, doodle iframe, info/share links,
refresh/random controls, saved preferences, cache expiry, unavailable or malformed
API responses, and retry. Additional regressions cover model defaults and rotation,
keyboard/pointer input inside artwork, codeword animations, both colour schemes,
and native wheel/keyboard/touch scrolling through window resizes. CI uses
deterministic artwork/API fixtures and a pinned
Playwright container. Linux environments without browser system libraries can use
`npx playwright install --with-deps chromium`.

`npm run test:live` additionally exercises the hosted API and artwork in an installed
extension. It depends on those services and is deliberately separate from CI.

The build uses CoffeeScript 2.7.0, esbuild, and Dart Sass. jQuery 4.0.0 (full build),
Underscore 1.13.8, and Backbone 1.6.1 are exact npm dependencies resolved through
`package-lock.json` and bundled locally. `src/js/vendor.js` provides the shared
globals used by the UI; templates are precompiled with the same Underscore version
so no runtime template evaluation is needed under Manifest V3. The ZIP includes
`THIRD-PARTY-NOTICES.txt` with the bundled libraries' license texts.

Models use standard Backbone with normalized catalogue metadata. Scrolling and
hover detection use native browser capabilities. DeepModel, iScroll, Modernizr,
legacy shims, and the unused GSAP/modal code have been removed. No third-party
JavaScript is maintained as copied source in this repository. `npm audit` now
covers the retained UI libraries as well as the build tools.

The existing Sass layout and syntax remain; compiler deprecation suppressions are
documented in the build script. Libraries inside remotely hosted sketches are
maintained separately and are not changed by an extension dependency update.

Editable files live under `src/`. Static resources formerly found only in `dist/`
now live under `src/public/`, including the manifest, host configuration, options
page, icons, and fonts. Changing hosts requires updating both `src/public/data/config.js`
and the manifest's host permission/content policy, along with the site links in
`src/data/templates.xml`, `src/html/index.html`, and `src/public/options.html`.
Only preferences use Chrome sync storage; catalogue data and rotation use local
storage. The catalogue is refreshed after 24 hours, with stale data retained if a
refresh fails. First-use failures offer a retry and a link to the website.

Publication choices also apply to existing caches: Fury Ribbons and Boobs are
excluded before selection and removed from saved data, including stale fallback
and older API responses. `UNPUBLISHED_SLUGS` in `src/coffee/AppData.coffee` mirrors
the site's exclusions. After installing this build, reload the extension and open
a new tab to apply the policy; an API response containing no eligible artwork
shows the normal retry screen.

## GitHub publishing

`.github/workflows/release.yml` builds and tests pull requests targeting `master`,
manual workflow runs, and pushes to `master`. A successful **push to `master`** also
creates a GitHub release with the tested ZIP and checksum, tagged
`build-<run-number>-<commit-prefix>`. Pull requests and manual runs produce workflow
artifacts only. The workflow has no Chrome Web Store steps.

The release job alone receives `contents: write` through GitHub's built-in token;
no additional secrets are needed. It publishes against the triggering commit,
keeps already published release assets unchanged on reruns, and updates the latest
release only when that commit is still the head of `master`. The extension's manifest
version is maintained in `src/public/manifest.json`; release tags distinguish builds
of the same version. Unpacked updates do not depend on a store version check.

See [the main project](https://github.com/treyturner/codedoodl.es) for restoration and
hosting details. Original extension by Neil Carpenter; see `LICENSE`.
