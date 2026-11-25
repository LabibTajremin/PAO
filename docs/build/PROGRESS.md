# Build progress

The agent updates this file in the same commit as each finished task. A new session reads
it first and continues from **Current task**.

## Status

| Phase | Status | PR | Notes |
|---|---|---|---|
| P00 Bootstrap | done | — | single-branch build, see ADR-0009 |
| P01 Contracts | done | — | OpenAPI 3.1 (121 ops), contracts, migrations |
| P02 Backend platform | done | — | |
| P03 Identity & access | done | — | |
| P04 Catalog, media, audit, settings | done | — | |
| P05 Customer | done | — | |
| P06 Provider & verification | done | — | |
| P07 Discovery & booking | done | — | |
| P08 Rating, notification, complaints | done | — | |
| P09 Admin API | done | — | ADR-0026 |
| P10 Flutter foundation | done | — | ADR-0027 |
| P11 Partner app | done | — | ADR-0028 |
| P12 Customer app | done | — | ADR-0029 |
| P13 Admin web | done | — | ADR-0030 |
| P14 End-to-end | done | — | ADR-0031 |
| P15 Interim backend | done | — | ADR-0032 |
| P16 Hardening & handover | done | — | ADR-0023, ADR-0032 |
| P17 .NET backend, COD & merchant dues | done | — | ADR-0034, ADR-0035 |
| P18 Notifications pop up | done | #12 | real-device check is owner action |
| P19 Repo layout & docs | done | #12 | |
| P20 Palette, type & theme | done | #12 | ADR-0038 |
| P21 Logo & app icons | done | #12 | update round 2026-11 |
| P22 Service icons | done | #12 | update round 2026-11 |
| P23 Artwork & tagline | done | #12 | update round 2026-11 |
| P24 Illustrations, welcome & sign-in | done | — | update round 2026-11 |
| P25 Scheduled delivery | done | — | update round 2026-11 |
| P26 Free Dhaka map | done | — | update round 2026-11 |
| P27 Motion | in_progress | — | update round 2026-11 |
| P28 Design polish & handover | todo | — | update round 2026-11 |

Status values: `todo` → `in_progress` → `in_review` (PR open) → `done` (merged).

## Current task

Update round 2026-11 — P27 (motion). P26 is committed locally and is pushed together with P27
(owner asked to batch); then P28 (no deployment: that step is the owner's).

Requirements and decisions: `docs/build/06-update-2026-11.md`. Run with the
`automatic-agentic-run` skill (`.claude/skills/automatic-agentic-run/SKILL.md`).

Branch and PR (owner's rule for this round): every phase P18–P28 is built on the one branch
`claude/update-2026-11` and goes into `main` through one pull request, which the owner merges
once all phases are done. Every push keeps all PR checks green, and the branch is kept merged
with `main` so `main` stays green after the merge. Preflight is not done yet.

## Environment notes

- Run the full `./pao ci` in the background and one heavy job at a time: two parallel .NET
  builds overload the 4-CPU container. .NET 10 SDK installs to `/root/.dotnet`.
- .NET 10 SDK (`Backend/global.json`), Flutter 3.47.7; Node.js only for `npx` (Redocly bundle).
- Local S3 is RustFS (ADR-0007); MinIO images are no longer published.
- Docker Hub rate-limits pulls here; `mirror.gcr.io/library/<image>` works as a mirror.
- Docker builds behind the sandbox proxy need `PAO_EXTRA_CA_FILE=/root/.ccr/ca-bundle.crt`
  in `.env` (build secret `extra_ca`).
- No Android SDK in the build container: APK builds run only in CI (`frontend.yml`).
- Backend integration tests (`Backend/tests/PAO.IntegrationTests`) need the compose
  Postgres/Redis/RustFS (ADR-0008); each spec file gets a private database and key prefix.
- `./pao gen` bundles the spec with redocly (npx) and builds `pao_api` with the
  `openapitools/openapi-generator-cli:v7.16.0` Docker image (Maven Central rate-limits).
- Every controller action carries an authorisation attribute matching the spec's
  `x-permission`; `AuthorizationTests` and the RBAC contract tests fail on any drift.
- Cross-area calls go through `I<Area>SharedService`, resolved by each area's peers on first use.
- Request timeouts run as a 15 s periodic sweep (`booking.expire_requests`) rather than a
  job per booking, so a missed run catches up on the next one.
- `./pao perf` needs only the .NET SDK (the load test is `Backend/tests/PAO.LoadTests`).
- Flutter tests that await real I/O (http_mock_adapter) inside `testWidgets` must use
  `tester.runAsync`, or they hang in fake async.
- `Backend/tests/PAO.TestKit` has the test environment, private databases and fakes.
- E2E: `infra/e2e/stack.sh` (separate compose project), `./pao test e2e` runs API and app
  journeys. Locally the admin web journey needs `CHROMEDRIVER`/`CHROME_EXECUTABLE`
  matching the installed Chromium (chromedriver 141 for Playwright's Chromium 141).

## Blockers

None.

## Log

- 2026-11-25 P26 Free Dhaka map (ADR-0042): `customer.places` (pg_trgm + PostGIS) holds Dhaka's
  OpenStreetMap areas, streets, places and addresses; `tools/places/build.sh` makes the file and
  `migrate import-places FILE` replaces the table in one transaction (guide
  `docs/guides/places.md`); dev/e2e seed a sample. `GET /v1/places/search` (English, Bangla,
  Bangla digits; areas first, nearest among equals) and `GET /v1/places/reverse` (300 m, launch
  area only), cached a day. The customer app's `ApiPlacesService` replaces Google;
  `PAO_MAPS_API_KEY` is gone from the app, scripts, CI and docs. Every map frame credits
  "© OpenStreetMap contributors". Deviation: drawing PMTiles with MapLibre is left to the owner
  (native plugin the widget tests and Linux journeys cannot run); `tools/places/tiles.sh` builds
  and uploads the tiles, and the apps keep the pin frame.
- 2026-11-25 P24 + P25 complete: every PR check green on f1c3d56.
- 2026-11-25 P25 Scheduled delivery (ADR-0041): `scheduled_delivery` services carry an admin-set
  schedule (patterns, windows, lead hours, cutoff, unit, quantity range). Customers order a
  subscription from one merchant; dates are computed in Asia/Dhaka (month ends, holidays from
  `booking.delivery_holidays`, counts) and only exceptions are stored. The five-minute sweep
  `booking.materialise_deliveries` makes each date past its cutoff an accepted booking, so COD,
  receipts, the commission debit and the job screens work per delivery. Customer: order form,
  orders list and detail (skip, pause, resume, cancel). Partner: new orders (accept/decline with
  a reason), this week's deliveries, declining a date. Admin: schedule editor on the service form
  and scheduled orders in the bookings monitor. Seeds Homemade food (Office lunch, Party food) and
  moves Catering and Monthly Bazar to the model. Tests: calendar units, integration journey and
  refusals, IDOR cases, e2e `DeliveryJourney` via `/__test/booking/deliveries`.
- 2026-11-25 P24.2–5 Sign-in per the demo in both apps: `PaoSignInLayout` (hero slot in the top 55%,
  ivory wordmark and the admin tagline over it, rounded sheet with "Welcome to PAO" / "Welcome to
  PAO Partner", the +880 field and "Send OTP", terms line; no social sign-in). The +880 prefix now
  shows before the field is focused. Onboarding uses `PaoOnboardingSlide` with the three slots of
  each app; the language chooser stays. `LookScope` hands the look to shared views: network
  failures in `ViewStateView` and `PagedView` show the `offline` scene, bookings and the partner
  feed show their empty scenes, booking confirmed and rate-the-customer show the success scenes.
  Goldens of the sign-in and welcome slide at 393 × 852 in light/dark × en/bn. Heroes keep their
  top-left clear for the wordmark; the scenes stand on a rounded mound so they sit on any page.
- 2026-11-25 P24.1 The 16 seed illustrations, drawn by `design/illustrations/draw.py` (motifs) and
  `scenes.py` (one scene per slot): navy heroes with ivory line art over a Dhaka skyline with
  Sangsad Bhaban, transparent scenes outlined in Primary elsewhere (rickshaw, tiffin, jute bag,
  tea cup, sleeping cat, paper boat, marigold garland); no text. The script copies every file
  to the backend seed and the `pao_ui` bundle so the copy test stays true.
- 2026-11-22 P23.4–5 Admin: Settings › Brand (tagline in both languages, live preview on the
  wordmark, the §6 suggestion chips) and Appearance › Illustrations (`/settings/appearance/
  illustrations`: every slot with size, status, light/dark preview, safe-area overlay, upload,
  reset; refusals name the expected size). Apps: `AppLookService` (pao_core) fetches
  `/v1/app-config` with its ETag, caches config and images in the app support folder, works
  offline; `PaoArtwork` (pao_ui) shows the bundled seed until the server image is cached, in a
  fixed-ratio box; empty notifications, search and jobs show their slot; receipts use the tagline.

- 2026-11-22 P23.1–3 Admin-managed artwork (ADR-0040): `admin.artwork_slots`, the 16 slots of §5
  in code, `GET /v1/admin/artwork`, `PUT|DELETE /v1/admin/artwork/{slotKey}` (size, ratio ±2%,
  alpha, SVG sanitised; refusals name the expected size), audited as `admin.ArtworkChanged`; files
  in the public bucket under `artwork/`. Public `GET /v1/app-config?app=` returns the tagline and
  the app's artwork with an ETag (304 on match). Setting `brand.tagline` (type `tagline`).
  `migrate seed` uploads `database/seed/artwork/*.svg` (placeholders from `design/illustrations/`
  until P24) and keeps slots an admin replaced. SVG and PNG/WebP checks moved to
  `PAO.Infrastructure/Images`.

- 2026-11-22 P22.4–5 `PaoServiceIcon` and `PaoIconTile.service` in `pao_ui` (library SVGs or the
  uploaded icon as a one-colour mask, tools icon as fallback) replace `catalogIcon()` in the customer
  and admin apps. Admin `IconField`: key field, light and dark previews, rules, and a picker with
  Library (search), Upload (`file_selector`) and From link tabs; refusals shown by reason.

- 2026-11-21 P22.2–3 Icons on the backend (ADR-0039): `iconUrl` on categories and services
  (`catalog/0003_icon_urls.sql`), only pointing at our public bucket's `catalog-icons/`;
  `GET|POST /v1/admin/catalog/icons` and `POST .../icons/from-link` (SVG sanitised, PNG/WebP square
  ≥ 96 px with alpha, links fetched once over https to public addresses only); `IconAdded` audited;
  start-up sets an anonymous-read policy on that folder (`S3_PUBLIC_READ_POLICY`, `S3_PUBLIC_BASE_URL`).
  Seeded categories and services use library keys. Integration tests run on CI only (no Docker here).

- 2026-11-21 P21 done: all PR checks green on 5cb0104.

- 2026-11-21 P22.1 Service icon library: 40 SVGs (24 px grid, 1.75 stroke, round caps,
  `currentColor`) generated by `design/icons/icons.py` into `design/icons/` and
  `pao_ui/assets/icons/`. Plumbing is pipe + tap + drop, homemade food a tiffin carrier, catering a
  handi, bazar a jute bag; carpentry is a hammer because a saw read as a key at 24 px.

- 2026-11-21 P21.6 Tests were already in tasks 1 and 4 (logo in both brightnesses, watermark layer
  in the PDF). `docs/guides/brand.md` explains the brand assets and regeneration, with preview sheets
  drawn by `tools/brand/preview.sh` from the generated icons and splash screens (no devices here, so
  the installed-build check is the owner's).

- 2026-11-21 P21.5 Two apps, two names: `tools/build-release.sh` copies each APK/AAB to
  `build/release/pao-<app>-<flavour>-<x.y.z-n>.<ext>` (`tools/lib/release_name.sh`, bats-tested);
  CI artifacts are `pao-<app>-<flavour>-android` and `pao-<app>-prod-ios`; documented in
  `docs/guides/release.md`.

- 2026-11-21 P21.4 Receipts carry the brand: logo tile header, `PaoWatermark` behind the items
  (ivory on dark) and the "Ask for it. PAO it." footer, on the customer receipt page and PDF and
  the partner receipt sheet.

- 2026-11-21 P21.3 Native splash via `tools/brand/splash.sh` (flutter_native_splash would need the
  same blocked dependency): Android pre-12 layer-list and 12+ SplashScreen API, light and night;
  iOS launch image and `LaunchBackground` colour with dark variants.

- 2026-11-21 P21.2 Launcher icons from `design/brand` via `tools/brand/app-icons.sh` (ImageMagick;
  flutter_launcher_icons cannot resolve beside melos): Android legacy + adaptive + monochrome,
  iOS single-size light/dark/tinted, admin favicon/PWA icons and manifest colours. The partner
  icons carry a tool badge (`design/brand/app-icons/partner/make.sh`).

- 2026-11-21 P21.1 `PaoLogo` (tile/wordmark from the brand SVGs via flutter_svg; ivory inverse
  on dark). Admin login and sidebar use it; the old admin PNG is gone; goldens show it.

- 2026-11-21 P20 complete: every PR check green on 98c1907 (goldens match on CI).

- 2026-11-21 P20.6 ADR-0038 (palette, type, light default, surfaces).

- 2026-11-21 P20.5 Goldens of the component gallery in light/dark × en/bn with the real Inter
  and Noto fonts (`pao_ui/test/goldens/`); the gallery takes `dark:` and follows a Bangla locale.

- 2026-11-21 P20.4 Even corners (cards 16, small 12, sheet tops 24; the leaf tip is gone);
  `PaoCard` is white with the navy shadow in light, an edged navy surface in dark.

- 2026-11-21 P20.3 Light by default (`ThemeModeController`, nothing saved = light). Appearance
  is its own page: Account › Appearance (customer), Profile › Appearance (partner); a Dark mode
  switch in the admin sidebar, saved in the browser.

- 2026-11-21 P20.2 Inter + Noto Sans Bengali bundled, system font on iOS (`PaoFonts.latinOn`);
  Fraunces and Plus Jakarta Sans removed; one scale (28/22/18/16/14/12), headings w600–700
  at -0.2. Fixed what the larger body text exposed: the home search hint overflowed narrow
  phones; the admin provider search clipped its retry button.

- 2026-11-21 P20.1 `PaoColors` on the §2 palette (light canvas F6F4EC, white cards, Ground
  wells; dark navy-ink 0E1322/151B2D/1B2338), new `elevated`, `sunken`, `spark`, `sparkInk`,
  `actionStrong`, `cardShadow`; `AccentPreset.navy` first and the default. AA tests extended.

- 2026-11-21 P19 complete: every PR check green on e319ed7 (Android builds included).

- 2026-11-21 CI: Android builds failed on 429s from Maven Central reached through the Gradle
  Plugin Portal; `.github/gradle/maven-mirror.gradle` now puts Google's Central mirror first in
  build-script repositories (checked with a local Gradle build).

- 2026-11-21 P19.4 READMEs for the root, `Backend`, `Frontend`, `infra`, `tools`, `docs` and every
  .NET project; `docs/guides/getting-started.md`; `Backend/docs/conventions.md` retitled.
  `appsettings.Local.example.json` stays in `Backend/`: every `config/*.json` is loaded at run time.

- 2026-11-21 P19.3 `Frontend/test/e2e` → `Frontend/e2e`; `PAO.code-workspace`, `.vscode/`
  (extensions, launch: API, Worker, Migrator, three apps; tasks: build, pao up/down/ci/test);
  only `.vscode/settings.local.json` is ignored.

- 2026-11-21 P19.2 `Backend/api`, `config`, `database/changes` (was "DB Changes"),
  `database/seed`, `docs` (+ `conventions.md` from PAO.AI); `Logs` untracked. Runtime paths
  (`PaoPaths`, `MigrationFiles`, seed), the image, gates and `pao` scripts follow. Deployments
  that set `PAO_HOME` by hand need the new folder names (`config/`, `database/`).

- 2026-11-21 P19.1 .NET projects in `Backend/src`, `Backend/tests`, `Backend/tools`; `PAO.sln` at
  the root. `PaoPaths` finds the backend by `Directory.Packages.props`; gates, `.editorconfig`,
  scripts, Dockerfile and docs follow.

- 2026-11-21 P18 complete: every PR check green on 9de597f.

- 2026-11-21 P18.5 `docs/guides/push-testing.md`; Notifications pages show "Notifications are
  off" with a settings shortcut (`PushOffNotice`, `PushService.allowed/openSettings`).

- 2026-11-21 P18.4 iOS: `Runner.entitlements` (aps-environment, time-sensitive) on all 12
  Runner configurations of both apps, `UIBackgroundModes` remote-notification. The App IDs and
  provisioning profiles need Push Notifications and Time Sensitive enabled (owner action).

- 2026-11-21 P18.1 permission reason sheet (`showPushReason`, en/bn) before the first
  permission prompt, after sign-in; `PushService.permissionUndecided`. flutter_local_notifications
  pinned to 22.x: 23.x needs compileSdk 37.

- 2026-11-20 P18.1/3 `LocalNotifier` (flutter_local_notifications) creates the three
  high-importance channels and shows foreground messages on Android; iOS foreground
  banners via presentation options; local and launch taps join `PushService.opened`;
  core library desugaring enabled in both apps.

- 2026-11-20 P18.2 FCM payload asks for heads-up: `PushChannels` maps every template to
  `pao_bookings` / `pao_account` / `pao_general`; Android channel_id + PRIORITY_HIGH, APNs
  priority 10, alert push type, time-sensitive for booking events.

Newest first. One line per finished task: `YYYY-MM-DD P00.1 short description (commit sha)`.

- 2026-11-14 Dark mode (System/Light/Dark in the customer and partner apps, admin follows
  the browser), theme-aware colours everywhere, Bangla theme wired to the locale, admin Home
  banners page (ADR-0037).
- 2026-11-14 Home banners API: `catalog.banners` with a seeded demo banner, admin CRUD at
  `/v1/admin/catalog/banners`, published list at `/v1/customer/banners` (ADR-0037 §2).
- 2026-11-14 Bangla type: Noto Sans Bengali replaces Hind Siliguri, larger size and line
  height when the app is in Bangla, so vowel signs are not clipped (ADR-0037).
- 2026-11-14 Sign-in fix from live logs: a repeat OTP request inside the resend minute with a
  live code answers 202 (no resend), so an app timing out on Render's cold start is not stuck
  on 429; the client IP skips private X-Forwarded-For hops (all users shared Render's 10.x).

- 2026-11-08 CI downloads retried: the Android NDK step, release files and image pulls in
  `tooling` (gitleaks, osv-scanner and promtool from their pinned images: GitHub kept answering
  release downloads with 504) and apt; main went red on these downloads, never on a test.

- 2026-11-07 MVP deployed: API on Render free (`https://pao-1-zbl8.onrender.com`,
  `JOBS_IN_API=true`), Neon set up from `database/changes/bundle` (68 tables, catalog seeded);
  the three apps' `config/prod.json` point at that host until `api.pao.com.bd` exists.

- 2026-11-06 MVP launch: `JOBS_IN_API` (default false) lets the API run the worker's relay
  and jobs through the same `AddBackgroundJobs` (`AddBackgroundJobsInApi`), for Render's
  free plan without a worker; start-up line `background jobs: in api|in worker`.

- 2026-11-06 MVP launch: `SMS_VERIFICATION_ENABLED`/`SMS_FIXED_CODE` (no SMS, fixed code,
  limits unchanged; prod starts without sslwireless), `Docs/Database/schema.md` with the
  index review (5 indexes in identity/0004, booking/0003, admin/0003),
  `database/changes/bundle/{schema,seed}.sql` from `migrate bundle`, checked in CI.

- 2026-10-25 P17 follow-up: last NestJS/JavaScript traces removed. k6 replaced by the C#
  load test `Backend/tests/PAO.LoadTests` (`./pao perf`, CI perf job without k6);
  `LegacyEnvironment` → `EnvironmentVariables`; comments, test names and docs neutral;
  security checklist evidence re-mapped to C# tests (3 tests added); PRD PDF regenerated.
- 2026-10-24 P17.8 cut-over: journeys ported to C# (13/13), k6 to Backend/tests/Load,
  NestJS backend and tooling deleted, ADR-0034 layout applied (Backend, Frontend, infra,
  tools, docs/guides, out/), CLI, hooks, workflows and docs switched.
- 2026-10-24 P17.6 apps for ADR-0035: partner due banner, 409 MERCHANT_DUE_LIMIT pay link,
  billing (ledger, payments) and pay screens; admin payments queue, merchant ledger,
  billing settings validation; customer cash on delivery; failure codes mapped; journeys
  added (7b8a0ff, d0e6902).
- 2026-10-17 P17.1 .NET foundation in Backend/: solution and projects, area skeletons
  and Shared contracts, config/Serilog/EF/migrator, mediator, mapper, auth, HTTP edge,
  Redis, outbox, jobs, storage, SMS, push, metrics, registration layout, Docs + gates
  (see git log for the sha).
- 2026-10-12 P15.6–7 cut-over: `./pao`, hooks and CI run the NestJS gates; API journeys
  ported to TypeScript (13/13); Go backend and Go tooling deleted, `backend/` is NestJS;
  CLAUDE.md, build docs and PRD describe NestJS; `./pao ci` green (5f2bcee).
- 2026-10-12 P15.5 parity: all 13 Go API journeys, partner/customer/admin app journeys
  and k6 nearby search (p95 125 ms at 50 rps) pass against the NestJS stack; fixed
  production route ordering and the perf seeder (20e33cd).
- 2026-10-12 P15.1–4 NestJS backend in `backend-nest/` (ADR-0032): platform (config, pino,
  metrics, pg + goose-compatible migrator, Redis keys/limiter/locks/idempotency, EdDSA
  JWT, argon2id, TOTP, AES-GCM, RBAC cache, spec-driven HTTP edge with RBAC decorators,
  outbox relay, advisory-lock scheduler, S3, health), sqlc TypeScript queries, all eleven
  modules with every Go test ported; 740 Jest tests at 100%. Go fixes on the way:
  Dhaka calendar dates for clearance issue date and 18th birthday, CA for the Go build.

- 2026-10-10 P11 partner app: sign-in, onboarding, resumable enrolment wizard with
  uploads, verification gate, home with presence heartbeat, requests with countdown,
  job flow (start code, extras, cash, rating), jobs, earnings, profile and push
  routing; 144 tests at 100%; dates generated as strings; journeys move to P14.
- 2026-10-09 P10 Flutter foundation: pao_core (Dio client, AppFailure, sessions with
  single-flight refresh, permissions, route guard + verification gate, connectivity,
  photo compression), pao_ui (10 accents, tokens, bundled fonts, 25 components, gallery,
  a11y tests), pao_l10n (en/bn ARB, every API error code, money/count/Dhaka-date
  formatters); the three apps boot with theme, language switch and a guarded route.
- 2026-10-09 P09 admin API: dashboard read model from events (cached 60 s), provider
  and customer search/detail/status via owners' contracts (ADR-0026), bookings monitor
  with filters, per-role RBAC table test over every protected route.
- 2026-10-09 P08.3 complaints: either party reports a booking (reason, description,
  ≤ 5 confirmed photos), TCK ticket numbers, admin queue with filters and cursor,
  assign/comment/resolve; `ComplaintResolved` notifies the reporter, is audited and a
  verified one flags the provider.
- 2026-10-09 P08.2 notification: bilingual templates for booking and verification
  events, inbox with read state, device tokens, FCM HTTP v1 push (capture adapter in
  dev/test), invalid tokens dropped, deduped per event; events for unknown bookings skip.
- 2026-10-09 P08.1 rating: reviews of completed bookings once per side with tags,
  incremental aggregates with distribution, public review lists, provider public
  profile; `testkit.CompletedJob` and `PAO_TEST_LOG=1` for server logs in tests.
- 2026-10-09 P07 perf: `./pao perf` seeds 2,000 online providers (`migrate perf-seed`)
  and runs `Backend/tests/Load/nearby.js`; nearby search p95 14 ms locally (limit 300 ms).
- 2026-10-09 P07.1–9 booking: state machine per booking-states.md, idempotent create with
  price/name snapshots, accept under provider + row locks (one active ASAP job), reject,
  timeout sweep, start code with lockout, catalog-only extras, cancel rules, lists,
  receipts, Dhaka earnings, nearby search with price summary, address/phone privacy;
  backend error codes now checked against the spec's ErrorCode enum.
- 2026-10-09 P06.3–6 verification: document steps with encrypted NID and block list,
  per-item review with reasons, levels recomputed under a row lock, Level 2 sessions
  with cooling-off, expiry and 30/7/1-day reminder jobs, audit of every decision,
  customer-schema privacy test; identity's provider gate now reads real levels.
- 2026-10-09 P06.1/2/7/8/9 provider: resumable enrolment wizard (profile steps, emergency
  contact OTP), profile with avatar, Redis GEO presence with heartbeat reaper,
  FindNearby (Level 2 first, women-only, working radius), read-model and quality flags.
- 2026-10-09 P05 customer: profile with verified avatar, up to 10 addresses with PostGIS
  pins inside Bangladesh, default switching and promotion on delete, launch-area check
  from the service_area setting, erase on AccountDeleted.
- 2026-10-09 P04 catalog, media, audit, settings: versioned prices with cached published
  tree and BN/EN trigram search, idempotent YAML seed (`./pao seed`), presigned uploads
  with per-purpose rules and audited 5-minute document views, orphan purge job,
  append-only audit log fed by events, typed admin settings with cache invalidation.
- 2026-10-09 P03 identity: phone OTP sign-in with rate limits and lockout, rotating
  refresh families with reuse detection, admin password + TOTP with cookie refresh,
  /v1/me*, account deletion, status changes with phone block, admin users and role
  editor, RBAC source, spec-wide 403 table test; test kit for full-API tests.
- 2026-10-09 P02 platform: config, logx, metrics, db (pool, tx, migrator), redisx (rate
  limiter, lock, idempotency, denylist), httpx (errors, cursors, spec validation,
  middleware chain, router, server), auth (EdDSA JWT, argon2id, TOTP), rbac cache,
  eventbus + outbox relay, River jobs, S3 storage, health, internal/app wiring.
- 2026-10-09 P01 contracts: OpenAPI spec + bundle, Go strict server and Dart client
  generation, 11 module contracts and READMEs, per-module migrations with RBAC seed,
  migration runner + test kit, booking state spec, catalog seed.
- 2026-10-09 P00 bootstrap: skeleton, Go module + healthz, Flutter workspace, Docker
  stack, `pao` CLI + bats tests, hooks, coverage gate, CI workflows, docs and ADRs.
