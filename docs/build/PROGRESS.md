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
| P19 Repo layout & docs | in_progress | — | update round 2026-11 |
| P20 Palette, type & theme | todo | — | update round 2026-11 |
| P21 Logo & app icons | todo | — | update round 2026-11 |
| P22 Service icons | todo | — | update round 2026-11 |
| P23 Artwork & tagline | todo | — | update round 2026-11 |
| P24 Illustrations, welcome & sign-in | todo | — | update round 2026-11 |
| P25 Scheduled delivery | todo | — | update round 2026-11 |
| P26 Free Dhaka map | todo | — | update round 2026-11 |
| P27 Motion | todo | — | update round 2026-11 |
| P28 Design polish & handover | todo | — | update round 2026-11 |

Status values: `todo` → `in_progress` → `in_review` (PR open) → `done` (merged).

## Current task

Update round 2026-11 — P19. Done: .NET projects (`Backend/src`, `tests`, `tools`, root
`PAO.sln`) and the data folders (`api`, `config`, `database/changes`, `database/seed`, `docs`,
`docs/conventions.md`; `Logs` ignored). Next: `Frontend/e2e`, the VS Code workspace and
`.vscode`, then the READMEs. P18 owner check (real phones) is open.

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
