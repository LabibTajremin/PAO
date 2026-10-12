# Testing, coverage and the `pao` CLI

A task is not done until its tests pass and coverage stays at 100% (PRD §10).

## 1. Test levels

| Level | Location | Runs against | Must cover |
|---|---|---|---|
| Unit (backend) | `backend/src/**/*.spec.ts` beside the code | in-memory fakes (`backend/test/fakes/`), `FakeClock` | every domain rule, state transition, use case branch, mapper, guard and interceptor |
| Unit / widget (Flutter) | `frontend/**/test/` | `mocktail` repositories | every bloc/cubit state, repository, mapper, widget state (loading, empty, error, success) |
| Integration (backend) | `backend/**/*.int-spec.ts` | real Postgres+PostGIS, Redis and S3 from the environment (ADR-0008); a private database, Redis prefix and buckets per spec | every repository method, every Redis adapter, every HTTP endpoint (success + each documented error), RBAC per route |
| Contract | the integration specs | OpenAPI spec | every response validated against the bundled `api/openapi.yaml` (Ajv) |
| Architecture | `./pao lint` | source tree | module import rules (dependency-cruiser), file-size limits |
| End-to-end (API) | `test/e2e/api/` (TypeScript, Jest) | full Docker stack (`test/e2e/stack.sh`) | complete journeys: enrol → verify → online → book → accept → start code → extras → complete → rate; cancel; timeout; expiry |
| End-to-end (apps) | `frontend/apps/*/integration_test/`, orchestrated by `test/e2e/mobile/` | the same stack + Linux desktop / Chrome | the same journeys through the real UI |
| Performance | `test/perf/` (k6) | Docker stack | nearby search p95 < 300 ms; request reaches provider < 3 s (PRD §11) |

Rules:

- Tests are named for behaviour: `it('rejects when the provider has an active job')`.
- Table-driven tests (`it.each`) for rule matrices (state machine: every from/to pair).
- No sleeping in tests; use the fake clock or polling helpers with deadlines.
- No network to real third parties; fakes implement the same ports.
- Each test owns its data (unique IDs, private database and key prefix).
- Flaky tests are bugs. Fix the cause; never retry-to-pass.

## 2. Coverage policy — 100%

The gate is **100% of hand-written code**, measured separately for the backend
(statements, lines and functions, Jest) and each Flutter package (lines).

Only these paths are excluded, and the list lives in `collectCoverageFrom` in
`backend/jest.config.ts` and `coverage_exclude` in each `pubspec.yaml` (Dart). Adding to
it requires an ADR.

- Generated code: `sqlc/` query functions, `*.gen.ts` (OpenAPI types), `pao_api/`,
  `*.g.dart`, `*.freezed.dart`, `l10n/generated/`.
- Composition roots `backend/src/{main,worker,migrate}.ts` and each app's `main.dart` —
  they are covered by the e2e smoke test instead.

Backend coverage combines the unit and integration projects in one Jest run
(`./pao test integration`); `./pao cover` checks it. If a line cannot be reached by any
test, it is dead code: delete it.

## 3. The `pao` CLI

A single bash script at the repository root. Every command exits non-zero on failure and
prints a one-line summary, so humans, git hooks and CI use the same entry point.

| Command | Does |
|---|---|
| `./pao setup` | checks Node.js 22.12+, npm, Docker (warns about sqlc, Flutter), runs `npm ci`, installs git hooks, creates `.env` |
| `./pao up` / `./pao down` | starts/stops the Docker stack (postgres, redis, minio, api, worker) |
| `./pao seed` | `/app/migrate up` and `seed` in the stack's image (5 MVP services, demo admins) |
| `./pao gen [--check]` | backend `npm run gen` (sqlc, spec bundle, spec types), Dart OpenAPI client, l10n; `--check` (or `CI=true`) fails if anything changed |
| `./pao lint [backend\|dart\|shell\|sizes]` | file sizes, shellcheck, backend ESLint + Prettier + dependency-cruiser + `tsc`, e2e journey lint, dart format, analyze, dart_code_linter |
| `./pao test unit` | CLI (bats), backend unit specs, Flutter unit/widget tests |
| `./pao test integration` | backend unit + integration specs in one run, with coverage |
| `./pao test e2e` | fresh e2e stack, `test/e2e/api` journeys, then the app journeys |
| `./pao test all` | unit → integration → e2e |
| `./pao cover` | enforces 100% (backend and every Flutter package), writes `coverage/summary.md` |
| `./pao security` | gitleaks, `npm audit --omit=dev --audit-level=high` (backend, e2e), osv-scanner over the Dart and npm lockfiles (`osv-scanner.toml`), trivy 0.64.1 (pinned image) over the source tree and, when `PAO_SCAN_IMAGE` is set, the backend image (`.trivyignore`) |
| `./pao ci` | lint → gen check → test all → cover → security (what CI runs) |
| `./pao phase finish <id>` | `ci`, push branch with retry, open PR via `gh`, print the PR URL |
| `./pao perf [e2e]` | k6 scripts against the local stack, or a fresh e2e stack |

Implementation rules for the script: `set -euo pipefail`, one function per command,
under 250 lines (helpers in `scripts/lib/*.sh`), `shellcheck` clean, and tested by
`test/cli/pao_test.bats` (bats-core) for argument handling and exit codes.

## 4. Git hooks (installed by `./pao setup`)

| Hook | Runs | Budget |
|---|---|---|
| `commit-msg` | Conventional Commit format check | < 1 s |
| `pre-commit` | file sizes and shellcheck; for staged backend files Prettier, ESLint, `tsc` and the unit specs related to them (`jest --findRelatedTests`); e2e lint, Dart lint + tests and bats when those areas are staged | < 60 s |
| `pre-push` | `./pao ci` (skipped only when the env var `PAO_SKIP_HOOK=1` is set by the CLI itself after it already ran `ci`) | full |

## 5. CI (GitHub Actions)

Workflows in `.github/workflows/`, all required for merging into `main`:

- `backend.yml`: Node 22 with npm cache; shellcheck, file sizes, lint, types and module
  rules; CLI tests; unit + integration specs against Postgres+PostGIS, Redis and RustFS
  service containers; the 100% coverage gate; `./pao security` (gitleaks, `npm audit`,
  osv-scanner, trivy on the source tree and the built backend image).
- `frontend.yml`: format, analyze, unit/widget tests with coverage per package, web build
  of admin, Android debug build of both apps.
- `e2e.yml`: Docker stack + TypeScript API journeys; k6 performance thresholds on a fresh
  stack; the app journeys per app (partner and customer on the Linux desktop, admin in
  Chrome).
- `contract.yml`: OpenAPI lint (`redocly lint`), generated code is up to date (backend
  `npm run gen` with sqlc, Dart client, l10n).

Branch protection on `main`: PR required, all four workflows green, linear history
(squash merge).
