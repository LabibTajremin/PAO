# Architecture

Source of truth: PRD §9 (architecture), §10 (standards), §11 (non-functional). This file
adds the concrete choices the PRD left open.

## 1. Repository layout

```
/
├── CLAUDE.md  README.md  LICENSE  .editorconfig  .gitignore  .env.example
├── pao                       one-line wrapper that runs tools/pao (the developer CLI)
├── Backend/                  the .NET solution (ADR-0034)
├── Frontend/                 Flutter workspace (customer, partner, admin web) + app journeys
├── docs/                     prd/, build/, adr/, guides/, runbooks/, HANDOVER.md, CONTRIBUTING.md
├── infra/                    docker-compose.yml, e2e/ (journey stack), ops/, security/
├── tools/                    pao CLI internals (lib/), hooks/, cli/ tests, fixtures/, release build
├── out/                      generated and ignored: coverage/, perf-fixture.json, e2e/ state
└── .github/workflows/        CI
```

### Backend/

```
Backend/
├── PAO.sln  global.json  Directory.Build.props  Directory.Packages.props
├── Api/                      the OpenAPI contract (openapi.yaml + paths/, schemas/, components/)
├── PAO.Core/                 API host: Areas/<Area>/{Controllers,Features,Services,Repositories},
│                             Registration/, Spec/openapi.gen.yaml (bundled contract)
├── PAO.Worker/               outbox relay + periodic jobs (same image, /app/worker)
├── PAO.Migrator/             migrations, seed data, perf fixture (up | seed | perf-seed N)
├── PAO.Lib/                  request/view models, events, error reasons, mapping, validation
├── PAO.EF/                   PaoDbContext, db models, configurations
├── PAO.Infrastructure/       platform: config, logging, Redis, crypto, HTTP edge, outbox,
│                             storage, SMS, push, metrics, health
├── PAO.BackgroundJobs/       scheduler, relay loop, platform jobs
├── Config/  DB Changes/  Seed/   JSON config per concern, goose SQL per module, seed data
├── Docs/                     areas, architecture, config, database, operations, testing, API
├── Tools/PAO.Gates/          size and docs checkers
├── Test/                     PAO.UnitTests, PAO.IntegrationTests, PAO.TestKit,
│                             PAO.E2ETests (start-up smoke + black-box journeys), Load/ (k6)
├── docker/                   Dockerfile and the api, worker, migrate entry points
└── scripts/                  ci.sh (the backend gates), coverage.py, gen-spec.sh
```

Modules (PRD §9.2) are ASP.NET areas: `Identity`, `Customer`, `Merchant` (provider),
`Verification`, `Catalog`, `Booking`, `Rating`, `Notification`, `Media`, `Admin`, `Audit`,
`Billing`. Boundary rules (PRD §9.3) are architecture tests in `PAO.UnitTests`
(`./pao lint backend`): an area reaches another only through its
`Services/Shared/I<Area>SharedService`; the platform never references an area. The binding
rules are in `Backend/PAO.AI/README.md`.

### Frontend/

```
Frontend/
├── apps/customer/            PAO            (Android + iOS)
├── apps/partner/             PAO Partner    (Android + iOS)
├── apps/admin/               PAO Admin      (Flutter Web)
├── packages/
│   ├── pao_core/             env config, Dio client, auth/session, token refresh,
│   │                         error mapping, permission service, router guards
│   ├── pao_api/              generated from Backend/Api/openapi.yaml — never edited by hand
│   ├── pao_ui/               design system: tokens, accent themes, shared widgets
│   ├── pao_l10n/             ARB files (en, bn) + generated localisations
│   └── pao_e2e/              shared support for the app journeys
└── test/e2e/                 run.sh: the app journeys against the e2e stack
```

Each app: `lib/features/<feature>/{data,domain,presentation}`, `lib/app/` (router, DI,
bootstrap). Unit and widget tests in each package's `test/`; app journeys in
`integration_test/` (Flutter requires both locations).

### Tests outside the projects

```
infra/e2e/stack.sh            a fresh Docker stack for the journeys (APP_ENV=test)
tools/cli/                    bats tests for the pao CLI and git hooks
tools/fixtures/               shared test data for the CLI tests
```

Backend unit and integration tests are separate projects under `Backend/Test/`;
integration tests run against real Postgres, Redis and S3 (ADR-0008).

## 2. Runtime view

- One API process, stateless, horizontally scalable (PRD §11).
- One worker process (same image, `/app/worker`) runs the outbox relay and periodic jobs.
- PostgreSQL 16 + PostGIS 3: system of record. One schema per module.
- Redis 7: sessions, tokens, permission caches, rate limits, locks, presence (§4).
- RustFS locally (S3-compatible, ADR-0007) / any S3 in production: private buckets, signed URLs only.
- FCM for push, SMS gateway and maps behind ports with fake adapters for dev/test.

## 3. Approved libraries

Adding anything else requires an ADR.

| Concern | Backend (.NET 10, ADR-0034) | Flutter |
|---|---|---|
| HTTP | ASP.NET Core (areas, controllers), own OpenAPI edge (`YamlDotNet`, bundled spec) | `dio`, generated `pao_api` |
| DB | EF Core + `Npgsql` (+ NetTopologySuite), goose-format SQL scripts (own migrator) | — |
| Redis | `StackExchange.Redis` | — |
| Jobs | in-process scheduler with a Postgres advisory lock per job | — |
| Auth | BouncyCastle (EdDSA JWT), `Otp.NET` (TOTP), `Konscious` argon2id, AES-256-GCM | `flutter_secure_storage` |
| Validation | `FluentValidation`, spec validation at the edge | `formz` |
| Logging/metrics | `Serilog` (JSON, date folders), `prometheus-net` | `sentry_flutter` (behind interface) |
| Storage | `AWSSDK.S3` | `image_picker`, `flutter_image_compress` |
| Push | FCM HTTP v1 | `firebase_messaging` |
| State/routing | — | `flutter_bloc`, `go_router`, `get_it` |
| Maps | — | `google_maps_flutter` behind `MapView` port |
| Testing | `xunit.v3`, `Microsoft.AspNetCore.TestHost`, `NetArchTest.Rules`, real services (ADR-0008), k6 | `flutter_test`, `bloc_test`, `mocktail`, `patrol` |
| Quality | .NET analyzers (warnings as errors), `dotnet format`, size/docs gates, `osv-scanner` on `packages.lock.json` | `very_good_analysis`, `dart_code_linter`, `very_good_cli` |

## 4. Redis design

Redis is required (owner decision; overrides PRD §9.1 "can be deferred"). Every key has
a TTL except presence sets, which are cleaned by the worker. Key prefix: `pao:{env}:`.

| Purpose | Key | Type | TTL |
|---|---|---|---|
| OTP code (argon2 hash + attempts) | `otp:{phone}` | hash | 5 min |
| OTP send rate limit | `rl:otp:phone:{phone}`, `rl:otp:ip:{ip}` | sliding window (ZSET) | 1 h |
| API rate limit | `rl:api:{subject}:{route}` | sliding window | 1 min |
| Refresh token family | `rt:{familyID}` → `{userID, currentTokenHash, roles}` | hash | 30 days |
| Access-token denylist (logout/ban) | `deny:jti:{jti}` | string | until token expiry (≤ 15 min) |
| Session list per user | `sess:{userID}` | set of familyIDs | 30 days |
| Role → permissions cache | `rbac:role:{role}:v{version}` | set | 1 h |
| Role → screens cache | `rbac:screens:{role}:v{version}` | set | 1 h |
| RBAC version (bumped on change) | `rbac:version` | int | none |
| Idempotency (booking create) | `idem:{userID}:{key}` | string (response hash) | 24 h |
| Booking accept lock | `lock:booking:{bookingID}` | `SET NX PX` | 10 s |
| Provider presence | `geo:online:{serviceID}` | GEO set | worker prunes > 2 min stale |
| Provider heartbeat | `hb:provider:{providerID}` | string | 90 s |
| Catalog read cache | `cache:catalog:v{version}` | string (JSON) | 10 min |
| Admin 2FA pending login | `mfa:{challengeID}` | hash | 5 min |

Rules: Redis is a cache and coordination layer, never the system of record. Every value
can be rebuilt from Postgres, except short-lived OTP/rate-limit state.

## 5. Authentication

- **Customers and providers:** phone + 6-digit OTP. Codes are hashed (argon2id) in Redis,
  5 attempts max, rate-limited per phone and per IP (PRD §11).
- **Admins:** email + password (argon2id) + TOTP 2FA (PRD A-01).
- **Tokens:** access JWT (EdDSA, 15 min, claims: `sub`, `roles`, `jti`, `ver`), refresh
  token (opaque, 256-bit random, 30 days) stored as a hash in the Redis family. Each
  refresh rotates the token. Reuse of an old refresh token revokes the whole family
  (theft detection).
- Logout, ban and role change: delete the family, add live `jti`s to the denylist and
  bump `rbac:version` when permissions change.
- The mobile apps keep tokens in `flutter_secure_storage`; the admin web app keeps the
  refresh token in an `HttpOnly; Secure; SameSite=Strict` cookie.

## 6. Roles, permissions and screen permissions

Permissions are `resource:action` strings. Roles are permission sets stored in the
`identity` schema; the matrix below is the seed. Super admins can edit role permissions
from the admin panel, which bumps `rbac:version`.

| Role | Key permissions |
|---|---|
| `customer` | `booking:create`, `booking:read:own`, `booking:cancel:own`, `review:create`, `address:manage:own`, `complaint:create` |
| `provider` | `provider:manage:own`, `verification:submit`, `job:respond`, `job:progress`, `earnings:read:own`, `review:create` |
| `verifier` | `verification:review`, `verification:docs:view`, `provider:read`, `level2:manage` |
| `catalog_manager` | `catalog:manage`, `settings:read` |
| `support_agent` | `complaint:manage`, `booking:read:any`, `customer:read`, `provider:read` |
| `super_admin` | all permissions, `admin_user:manage`, `settings:manage`, `audit:read`, `role:manage` |

Enforcement happens at two layers:

1. **API (authoritative):** every operation's `x-permission` in the OpenAPI spec, checked
   by a global guard before the controller runs,
   plus ownership checks in use cases (`:own` permissions compare `sub` to the resource
   owner). Missing permission → `403 FORBIDDEN`.
2. **Screens (UX):** `GET /v1/me/permissions` returns `{roles, permissions, screens}`.
   Each Flutter route declares a screen ID (from `05-screens.md`); a `go_router` redirect
   guard hides or blocks screens the user lacks. Screen IDs per role live in the
   `identity.role_screens` table and are cached in Redis.

Providers have an extra **state gate**: until verification Level ≥ 1, only the screens
`M01–M14` (onboarding, enrolment, verification) are allowed (PRD §8.5). An expired
document returns the provider to this gate.

## 7. Security controls

| Area | Control |
|---|---|
| Transport | HTTPS only in deployed envs; HSTS; TLS terminates at the load balancer |
| Headers | `X-Content-Type-Options`, `X-Frame-Options: DENY`, strict CSP on admin web |
| Input | All requests validated against the OpenAPI schema (Ajv); max body 1 MB (uploads go direct to storage) |
| SQL | EF Core queries and parameterised raw SQL only; no string-built SQL |
| AuthZ | Deny by default; every route has an explicit permission |
| Rate limits | OTP per phone/IP; API per user and per IP; login per account |
| Sensitive data | NID numbers encrypted with AES-256-GCM (key from env); documents in private buckets, 5-minute signed URLs, every view audited (PRD §6.6) |
| Privacy | Exact customer address only after acceptance; provider location only while online or on a job (PRD §11) |
| Audit | `audit.entries` is append-only (DB trigger rejects UPDATE/DELETE) |
| Secrets | Env vars only; `.env.example` documents them; `gitleaks` in CI |
| Dependencies | `osv-scanner` over the Dart `pubspec.lock` and the NuGet `packages.lock.json` files, `trivy` source and image scan; accepted findings in `infra/security/osv-scanner.toml` / `infra/security/trivyignore` |
| Mobile | Certificate pinning on release builds (SPKI SHA-256, `--dart-define=PAO_PIN_SHA256`); no secrets in the app binary; screenshots blocked on start-code and document screens |

## 8. Events (published through the outbox)

`identity`: `AccountCreated`, `AccountDeleted` · `verification`: `ProviderLevelChanged`,
`DocumentRejected`, `DocumentExpired` · `booking`: `BookingRequested`, `BookingAccepted`,
`BookingRejected`, `BookingTimedOut`, `ProviderOnTheWay`, `ProviderArrived`,
`BookingStarted`, `ExtraItemsProposed`, `ExtraItemsDecided`, `BookingCompleted`,
`BookingCancelled` · `rating`: `ReviewSubmitted` · `admin`: `ComplaintResolved`.

`notification` subscribes to all booking and verification events. `audit` subscribes to
every event that changes a person's status or money.

## 9. Background jobs (scheduler)

Only periodic jobs. The worker runs an in-process scheduler (`platform/jobs/scheduler.ts`)
with `every(ms)` and `dailyAt(hour, minute)` (Asia/Dhaka); each run takes a Postgres
advisory lock named after the job, so with several workers exactly one runs it.

| Job | Schedule | Effect |
|---|---|---|
| `booking.expire_requests` | every 15 s | requests past the accept limit (PRD §5): `Requested → TimedOut` |
| `verification.expire_documents` | daily 02:00 | marks expired documents, drops level, publishes `DocumentExpired` |
| `verification.expiry_reminders` | daily 09:00 | push 30/7/1 days before expiry (P-11) |
| `provider.reap_lost_presence` | every minute | removes stale providers from GEO sets |
| `media.purge_orphans` | daily 03:30 | deletes uploads never attached to a record |
| `verification.purge_closed` | daily 03:45 | deletes the documents and verification records of accounts closed longer than `documents.retention_days` (ADR-0023) |
| `outbox.purge_published` | daily 03:00 | drops delivered outbox rows |

The outbox relay runs continuously beside the scheduler and delivers outbox rows to
subscribers, at least once.
