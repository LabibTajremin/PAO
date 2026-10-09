# Testing, coverage and the `pao` CLI

A task is not done until its tests pass and coverage stays at 100% (PRD §10).

## 1. Test levels

| Level | Location | Runs against | Must cover |
|---|---|---|---|
| Unit (Go) | `backend/**/_test.go` beside code | fakes from `go.uber.org/mock`, fake clock | every domain rule, state transition, use case branch, mapper, middleware |
| Unit / widget (Flutter) | `frontend/**/test/` | `mocktail` repositories | every bloc/cubit state, repository, mapper, widget state (loading, empty, error, success) |
| Integration (Go) | `test/backend/integration/` | real Postgres+PostGIS and Redis via testcontainers | every repository method, every Redis adapter, every HTTP endpoint (success + each documented error), RBAC per route |
| Contract | `test/backend/integration/contract/` | OpenAPI spec | every response validated against `api/openapi.yaml` (`kin-openapi`) |
| Architecture | `./pao lint` | source tree | module import rules (`go-arch-lint`), file-size limits |
| End-to-end (API) | `test/e2e/api/` | full Docker stack (`docker compose up`) | complete journeys: enrol → verify → online → book → accept → start code → extras → complete → rate; cancel; timeout; expiry |
| End-to-end (apps) | `frontend/apps/*/integration_test/`, orchestrated by `test/e2e/mobile/` | Docker stack + emulator / Chrome | the same journeys through the real UI with Patrol |
| Performance | `test/perf/` (k6) | Docker stack | nearby search p95 < 300 ms; request reaches provider < 3 s (PRD §11) |

Rules:

- Tests are named for behaviour: `TestAcceptBooking_RejectsWhenProviderHasActiveJob`.
- Table-driven tests in Go for rule matrices (state machine: every from/to pair).
- No `time.Sleep` in tests; use the fake clock or polling helpers with deadlines.
- No network to real third parties; fakes implement the same ports.
- Each test owns its data (unique IDs); integration tests truncate their module schema.
- Flaky tests are bugs. Fix the cause; never retry-to-pass.

## 2. Coverage policy — 100%

The gate is **100% statement coverage of hand-written code**, measured separately for
Go (`go-test-coverage`) and each Flutter package (`very_good test --min-coverage 100`).

Only these paths are excluded, and the list lives in `.coverage-exclude` (Go) and
`coverage_exclude` in each `pubspec.yaml` (Dart). Adding to it requires an ADR.

- Generated code: `*.sql.go` (sqlc), `*.gen.go` (oapi-codegen, mocks), `pao_api/`,
  `*.g.dart`, `*.freezed.dart`, `l10n/generated/`.
- Composition roots `backend/cmd/*/main.go` and each app's `main.dart` — they are covered
  by the e2e smoke test instead.

Go coverage combines unit and integration runs (`-coverpkg=./internal/...`, merged with
`go tool covdata`). If a line cannot be reached by any test, it is dead code: delete it.

## 3. The `pao` CLI

A single bash script at the repository root (built in P00). Every command exits non-zero
on failure and prints a one-line summary, so humans, git hooks and CI use the same entry
point.

| Command | Does |
|---|---|
| `./pao setup` | checks tool versions, installs git hooks, copies `.env.example` → `.env` |
| `./pao up` / `./pao down` | starts/stops the Docker stack (postgres, redis, minio, api, worker) |
| `./pao seed` | applies migrations and loads seed data (5 MVP services, demo users) |
| `./pao gen` | runs sqlc, oapi-codegen, mockgen, Dart OpenAPI client, l10n — then fails if git sees uncommitted generated changes in CI |
| `./pao lint` | gofmt/goimports, golangci-lint, go-arch-lint, gosec, file-size check, dart format, flutter analyze, dart_code_linter |
| `./pao test unit` | Go unit tests + all Flutter unit/widget tests |
| `./pao test integration` | Go integration + contract tests (testcontainers) |
| `./pao test e2e` | brings the stack up, runs `test/e2e/api`, then Patrol app journeys |
| `./pao test all` | unit → integration → e2e |
| `./pao cover` | merges coverage, enforces 100%, writes `coverage/summary.md` |
| `./pao security` | govulncheck, gitleaks, osv-scanner, trivy |
| `./pao ci` | lint → gen check → test all → cover → security (what CI runs) |
| `./pao phase finish <id>` | `ci`, push branch with retry, open PR via `gh`, print the PR URL |
| `./pao perf` | k6 scripts against the local stack |

Implementation rules for the script: `set -euo pipefail`, one function per command,
under 250 lines (split helpers into `scripts/lib/*.sh` if needed), `shellcheck` clean, and
tested by `test/cli/pao_test.bats` (bats-core) for argument handling and exit codes.

## 4. Git hooks (installed by `./pao setup`)

| Hook | Runs | Budget |
|---|---|---|
| `commit-msg` | Conventional Commit format check | < 1 s |
| `pre-commit` | `./pao lint` on staged files + `./pao test unit` for touched packages | < 60 s |
| `pre-push` | `./pao ci` (skipped only when the env var `PAO_SKIP_HOOK=1` is set by the CLI itself after it already ran `ci`) | full |

## 5. CI (GitHub Actions)

Workflows in `.github/workflows/`, all required for merging into `main`:

- `backend.yml`: lint, arch rules, unit, integration (service containers), coverage, security.
- `frontend.yml`: format, analyze, unit/widget tests with coverage per package, web build
  of admin, Android debug build of both apps.
- `e2e.yml`: Docker stack + API journeys + Patrol on an Android emulator (and Chrome for
  admin).
- `contract.yml`: OpenAPI lint (`redocly lint`), generated code is up to date.

Branch protection on `main`: PR required, all four workflows green, linear history
(squash merge).
