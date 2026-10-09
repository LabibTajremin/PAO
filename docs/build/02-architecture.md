# Architecture

Source of truth: PRD §9 (architecture), §10 (standards), §11 (non-functional). This file
adds the concrete choices the PRD left open.

## 1. Repository layout

```
/
├── CLAUDE.md                 agent rules
├── README.md                 product + one-command local run
├── pao                       developer CLI (bash) — tests, lint, coverage, phases
├── docker-compose.yml        postgres+postgis, redis, minio, api (local + CI)
├── api/openapi.yaml          REST contract shared by backend and frontend
├── backend/                  Go modular monolith
├── frontend/                 Flutter melos workspace (customer, partner, admin web)
├── test/                     cross-system tests and shared test infrastructure
├── docs/                     prd/, build/, adr/, architecture.md, glossary, runbooks
└── .github/workflows/        CI
```

### backend/

```
backend/
├── cmd/api/main.go           composition root only: config → infra → modules → server
├── cmd/worker/main.go        background jobs + outbox relay (same binary image)
├── internal/platform/        shared infrastructure, no business rules
│   ├── config/  db/  redisx/  httpx/  auth/  rbac/  eventbus/  outbox/
│   ├── jobs/  storage/  clock/  idgen/  logx/  metrics/  validate/
└── internal/modules/<module>/
    ├── contract/             PUBLIC: service.go (interface), dto.go, events.go
    ├── domain/               entities, value objects, rules, errors — no I/O imports
    ├── app/                  use cases, one file per use case
    ├── port/                 repository + gateway interfaces used by app/
    ├── adapter/postgres/     sqlc queries + repository implementations
    ├── adapter/http/         handlers, request validation, error mapping
    ├── adapter/inproc/       implements contract/ for other modules
    ├── module.go             wiring: routes, subscribers, jobs
    └── README.md
backend/migrations/<module>/  goose SQL migrations, one Postgres schema per module
```

Modules (PRD §9.2): `identity`, `customer`, `provider`, `verification`, `catalog`,
`booking`, `rating`, `notification`, `media`, `admin` (admin users, settings, complaints),
`audit`.

Boundary rules (PRD §9.3) are enforced by `go-arch-lint` in CI:
`modules/A/**` may import only `modules/B/contract` and `platform/**`. `domain/` imports
only the standard library and its own module's `domain/`.

### frontend/

```
frontend/
├── melos.yaml
├── apps/customer/            PAO            (Android + iOS)
├── apps/partner/             PAO Partner    (Android + iOS)
├── apps/admin/               PAO Admin      (Flutter Web)
└── packages/
    ├── pao_core/             env config, Dio client, auth/session, token refresh,
    │                         error mapping, permission service, router guards
    ├── pao_api/              generated from api/openapi.yaml — never edited by hand
    ├── pao_ui/               design system: tokens, accent themes, shared widgets
    └── pao_l10n/             ARB files (en, bn) + generated localisations
```

Each app: `lib/features/<feature>/{data,domain,presentation}`, `lib/app/` (router, DI,
bootstrap). Unit and widget tests in each package's `test/`; app journeys in
`integration_test/` (Flutter requires both locations).

### test/

```
test/
├── backend/integration/      Go: repositories + HTTP API against real Postgres/Redis
│                             (testcontainers), run with -coverpkg over backend/internal
├── e2e/api/                  Go: black-box journeys against the running Docker stack
├── e2e/mobile/               Patrol/integration_test orchestration scripts + fixtures
├── fixtures/                 seed data, sample documents, deterministic clocks
└── perf/                     k6 scripts (nearby search p95, booking dispatch)
```

Go unit tests stay beside the code (`_test.go`) because Go tooling requires it.

## 2. Runtime view

- One API binary, stateless, horizontally scalable (PRD §11).
- One worker process (same image, `cmd/worker`) runs the outbox relay and scheduled jobs.
- PostgreSQL 16 + PostGIS 3: system of record. One schema per module.
- Redis 7: sessions, tokens, permission caches, rate limits, locks, presence (§4).
- MinIO locally / any S3 in production: private buckets, signed URLs only.
- FCM for push, SMS gateway and maps behind ports with fake adapters for dev/test.

## 3. Approved libraries

Adding anything else requires an ADR.

| Concern | Go | Flutter |
|---|---|---|
| HTTP | `go-chi/chi/v5`, `oapi-codegen` (strict server types) | `dio`, generated `pao_api` |
| DB | `jackc/pgx/v5`, `sqlc`, `pressly/goose/v3` | — |
| Redis | `redis/go-redis/v9` | — |
| Jobs | `riverqueue/river` (Postgres-backed) | — |
| Auth | `golang-jwt/jwt/v5` (EdDSA), `pquerna/otp` (TOTP), `x/crypto/argon2` | `flutter_secure_storage` |
| Validation | `go-playground/validator/v10` | `formz` |
| Logging/metrics | `log/slog` (JSON), `prometheus/client_golang` | `sentry_flutter` (behind interface) |
| Storage | `aws-sdk-go-v2/service/s3` | `image_picker`, `flutter_image_compress` |
| Push | `firebase.google.com/go/v4/messaging` | `firebase_messaging` |
| State/routing | — | `flutter_bloc`, `go_router`, `get_it` |
| Maps | — | `google_maps_flutter` behind `MapView` port |
| Testing | `testing`, `stretchr/testify`, `testcontainers-go`, `go.uber.org/mock` | `flutter_test`, `bloc_test`, `mocktail`, `patrol` |
| Quality | `golangci-lint`, `go-arch-lint`, `gosec`, `govulncheck`, `go-test-coverage` | `very_good_analysis`, `dart_code_linter`, `very_good_cli` |

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

1. **API (authoritative):** `rbac.Require("booking:cancel:own")` middleware on every route,
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
| Input | All request bodies validated against the OpenAPI schema and `validator` tags; max body 1 MB (uploads go direct to storage) |
| SQL | Only parameterised `sqlc` queries; no string-built SQL |
| AuthZ | Deny by default; every route has an explicit permission |
| Rate limits | OTP per phone/IP; API per user and per IP; login per account |
| Sensitive data | NID numbers encrypted with AES-256-GCM (key from env); documents in private buckets, 5-minute signed URLs, every view audited (PRD §6.6) |
| Privacy | Exact customer address only after acceptance; provider location only while online or on a job (PRD §11) |
| Audit | `audit.entries` is append-only (DB trigger rejects UPDATE/DELETE) |
| Secrets | Env vars only; `.env.example` documents them; `gitleaks` in CI |
| Dependencies | `govulncheck`, `gosec`, `osv-scanner` for Dart, `trivy` image scan in CI |
| Mobile | Certificate pinning on release builds; no secrets in the app binary; screenshots blocked on start-code and document screens |

## 8. Events (published through the outbox)

`identity`: `AccountCreated`, `AccountDeleted` · `verification`: `ProviderLevelChanged`,
`DocumentRejected`, `DocumentExpired` · `booking`: `BookingRequested`, `BookingAccepted`,
`BookingRejected`, `BookingTimedOut`, `ProviderOnTheWay`, `ProviderArrived`,
`BookingStarted`, `ExtraItemsProposed`, `ExtraItemsDecided`, `BookingCompleted`,
`BookingCancelled` · `rating`: `ReviewSubmitted` · `admin`: `ComplaintResolved`.

`notification` subscribes to all booking and verification events. `audit` subscribes to
every event that changes a person's status or money.

## 9. Background jobs (River)

| Job | Trigger | Effect |
|---|---|---|
| `booking.expire_request` | scheduled at request time + accept limit (PRD §5) | `Requested → TimedOut` |
| `verification.expire_documents` | daily 02:00 Asia/Dhaka | marks expired documents, drops level, publishes `DocumentExpired` |
| `verification.expiry_reminders` | daily | push 30/7/1 days before expiry (P-11) |
| `provider.prune_presence` | every minute | removes stale providers from GEO sets |
| `outbox.relay` | continuous | delivers outbox rows to subscribers, at-least-once |
| `media.purge_orphans` | daily | deletes uploads never attached to a record |
