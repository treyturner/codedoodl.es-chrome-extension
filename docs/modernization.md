# Extension modernization — 2026-09-29

All three stages are complete. This work starts from the uncommitted Manifest V3,
host migration, and GitHub release implementation, not the historical extension
on `origin/master`. The hosted sketches, permissions, catalogue/preferences storage
format, and release workflow are unchanged.

## Dependency changes

| Component | Baseline | Delivered |
| --- | --- | --- |
| Compiler | `coffee-script` 1.12.7 | `coffeescript` 2.7.0 |
| jQuery | Copied 2.1.0 | npm 4.0.0, full build |
| Underscore | Copied 1.7.0 | npm 1.13.8 |
| Backbone | Copied 1.1.2 | npm 1.6.1 |
| Backbone.DeepModel | Copied 0.11.0 | Standard Backbone models with normalized input |
| iScroll | Copied 5.1.3 | Native scrolling |
| Modernizr | Copied 2.6.2 | Native capability queries and CSS transforms |
| TweenLite / CSSPlugin / EasePack | Copied legacy versions | Removed with unused modal code |
| Legacy browser shims | Copied source | Removed |

Retained libraries are exact dependencies in the lockfile and bundled locally.
The package includes their license texts. Build tools remain pinned: Node 24.21.0,
npm 11.19.0, esbuild 0.28.2, Sass 1.105.0, Playwright 1.63.0, fflate 0.8.3, and
xml2js 0.6.2. The Sass source migration remains a separate maintenance task.

## Stage results

1. Preserved the source/package baseline; added metadata and artwork-input fixtures;
   removed unused modal, authentication, social SDK, and template-model code.
   Installed-extension and package checks passed.
2. Upgraded Underscore/Backbone, removed DeepModel, migrated CoffeeScript class
   initialization, then tested jQuery 2.2.4, 3.7.1, and 4.0.0 both with their matching
   Migrate versions (1.4.1, 3.6.0, 4.0.2) and without Migrate. Replaced deprecated
   iframe focus shorthand; all migration warnings were resolved. Model, browser,
   and packaging checks passed. No migration helper remains installed or bundled.
3. Replaced scrolling and feature detection, removed all remaining copied JavaScript
   libraries, and added resize, hover, touch, colour-scheme, and delayed-focus
   regressions. An artwork finishing its load no longer steals keyboard focus from
   an open information panel; closing the panel returns focus to loaded artwork.

## Validation

- Final `npm test`: **9 passed** locally and **9 passed** after a clean `npm ci`
  inside the workflow's pinned Playwright container, using the pinned Node/npm.
- `npm run test:live`: **1 passed** against both hosted instances.
- `npm audit`: **0 vulnerabilities**, including the retained browser dependencies.
- Release workflow: actionlint 1.7.12 passed with the existing runner-label configuration.
- Package tests: permissions/CSP, complete local resources, license notices, legacy
  library removal, store independence, checksum, and repeatable packaging passed.
- The clean container and local build produced byte-identical ZIPs.

Browser checks cover real extension APIs and new-tab override, autoplay and options,
cache failure/recovery and rotation, iframe keyboard/pointer input, light/dark
styling, completed text animations, native wheel/Home/End scrolling, touch gestures,
and information-panel resizing at widths 1280, 750, and 520 with heights down to 400.
The delayed-focus regression holds the artwork response until the panel is open,
then checks that focus stays in the panel after the artwork's focus timer expires.

## Package measurements

| Measurement | Baseline | Delivered | Reduction |
| --- | ---: | ---: | ---: |
| Release ZIP | 482,730 bytes | 436,655 bytes | 9.5% |
| All packaged JavaScript, uncompressed | 351,376 bytes | 198,986 bytes | 43.4% |
| Vendor JavaScript, uncompressed | 272,964 bytes | 132,474 bytes | 51.5% |

Stage 3 ZIP, before the publication-policy follow-up: `release/codedoodles-extension.zip`.

SHA-256: `28ebd0355deb659a858a0d222681cddb3a4935fc2910ea4b319fae3a1689bae2`.

## Publication-policy follow-up

Fury Ribbons and Boobs are excluded from cached catalogues and older API
responses. Fresh and stale caches are purged without resetting surviving viewed
state; when nothing eligible remains, the normal fetch/retry path is used.
The installed-extension regression covers all of these paths and asserts that
neither unpublished artwork nor its previews are requested.

The final `release/codedoodles-extension.zip`, including the updated README, is
**436,982 bytes**, with SHA-256
`bf700570da1533896b7a508ffc5990501936327afffe8bf8fc5c921c1f7c1770`.
Package/installed-extension tests: **10 passed** locally and after a clean locked
install in the pinned CI container. Live-instance smoke test: **1 passed**.
The fresh local and container ZIPs are byte-identical; the dependency audit has
zero findings. Dependencies, permissions, and release behavior are unchanged.

## Local recovery and evidence

The ignored `test-results/modernization-baseline/` directory contains `source.tar.gz`
(including the original untracked files), the starting Git status/patch and HEAD,
dependency/size inventory, baseline test log, and original ZIP/checksum. Extract the
source archive into an **empty directory** to inspect or rebuild it without changing
the current worktree. Source-archive SHA-256:
`c2ca51c2e645b2409f280dba9db5e64e782b74478da9f2c576e6394535929b35`.

Stage and migration logs, screenshots/traces, intermediate ZIPs, live-test results,
and clean-container outputs are also under `test-results/`. These local evidence
files are not committed or included in the extension ZIP.
