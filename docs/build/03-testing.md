# Testing, coverage and the `pao` CLI

A task is not done until its tests pass and coverage stays at 100% (PRD §10).

## 1. Test levels

| Level | Location | Runs against | Must cover |
|---|---|---|---|
| Unit (backend) | `Backend/Test/PAO.UnitTests/` (xUnit v3) | in-memory fakes (`Backend/Test/PAO.TestKit`), the fake clock | every domain rule, state transition, use case branch, mapper, guard and interceptor |
| Unit / widget (Flutter) | `Frontend/**/test/` | `mocktail` repositories | every bloc/cubit state, repository, mapper, widget state (loading, empty, error, success) |
| Integration (backend) | `Backend/Test/PAO.IntegrationTests/` | real Postgres+PostGIS, Redis and S3 from the environment (ADR-0008); a private database, Redis prefix and buckets per test class | every repository method, every Redis adapter, every HTTP endpoint (success + each documented error), RBAC per route |
| Contract | the integration tests | OpenAPI spec | every response validated against the bundled `Backend/Api/openapi.yaml`; every spec operation served |
| Architecture | `./pao lint` (`Category=Gate` tests) | source tree | area boundaries, authorisation attributes, mapping profiles, file-size limits, docs coverage |
| Start-up smoke | `Backend/Test/PAO.E2ETests/StartupSmokeTests.cs` | the built hosts as processes | migrator, API and worker start, answer health and metrics, fail fast on bad config |
| End-to-end (API) | `Backend/Test/PAO.E2ETests/Journeys/` (C#, `Category=Journey`) | full Docker stack (`infra/e2e/stack.sh`) | complete journeys: enrol → verify → online → book → accept → start code → extras → complete → rate; cancel; timeout; expiry |
| End-to-end (apps) | `Frontend/apps/*/integration_test/`, orchestrated by `Frontend/test/e2e/` | the same stack + Linux desktop / Chrome | the same journeys through the real UI |
| Performance | `Backend/Test/PAO.LoadTests/` (C# console, HttpClient) | Docker stack | nearby search p95 < 300 ms; request reaches provider < 3 s (PRD §11) |

Rules:

- Tests are named for behaviour: `Rejects_when_the_provider_has_an_active_job` (C#),
  `test('rejects when the provider has an active job')` (Dart).
- Table-driven tests (`[Theory]`, Dart loops) for rule matrices (state machine: every from/to pair).
- No sleeping in tests; use the fake clock or polling helpers with deadlines.
- No network to real third parties; fakes implement the same ports.
- Each test owns its data (unique IDs, private database and key prefix).
- Flaky tests are bugs. Fix the cause; never retry-to-pass.

## 2. Coverage policy — 100%

The gate is **100% of hand-written code**, measured separately for the backend
(lines, unit and integration reports merged by `Backend/scripts/coverage.py`) and each
Flutter package (lines).

Only these paths are excluded, and the list lives in `Backend/coverage.config` and
`coverage_exclude` in each `pubspec.yaml` (Dart). Adding to it requires an ADR.

- Generated code (`GeneratedCode`/`CompilerGenerated` attributes), `pao_api/`, `*.g.dart`,
  `*.freezed.dart`, `l10n/generated/`.
- The composition roots `PAO.Core`, `PAO.Worker` and `PAO.Migrator` `Program.cs` and each
  app's `main.dart` — they are covered by the start-up smoke tests instead.

Backend coverage combines the unit and integration projects (`./pao test integration`,
which is `Backend/scripts/ci.sh test`, report in `out/coverage/backend/`); `./pao cover`
checks it. If a line cannot be reached by any
test, it is dead code: delete it.

## 3. The `pao` CLI

`./pao` at the repository root is a one-line wrapper around `tools/pao`. Every command exits non-zero on failure and
prints a one-line summary, so humans, git hooks and CI use the same entry point.

| Command | Does |
|---|---|
| `./pao setup` | checks git, Docker and the .NET SDK of `Backend/global.json` (warns about Flutter, npx), restores NuGet packages, installs git hooks (`tools/hooks`), creates `.env` |
| `./pao up` / `./pao down` | starts/stops the Docker stack (postgres, redis, minio, api, worker) |
| `./pao seed` | `/app/migrate up` and `seed` in the stack's image (5 MVP services, demo admins) |
| `./pao gen [--check]` | bundles `Backend/Api/openapi.yaml` into `PAO.Core/Spec/openapi.gen.yaml` (Redocly), Dart OpenAPI client, l10n; `--check` (or `CI=true`) fails if anything changed |
| `./pao lint [backend\|dart\|shell\|sizes]` | Dart file sizes, shellcheck, backend build (warnings as errors) + `dotnet format` + gates (architecture, authorisation, size, docs; journeys included), dart format, analyze, dart_code_linter |
| `./pao test unit` | CLI (bats), backend unit tests, Flutter unit/widget tests |
| `./pao test integration` | backend unit + integration tests with merged coverage (`Backend/scripts/ci.sh test`) |
| `./pao test e2e` | start-up smoke tests, a fresh e2e stack (`infra/e2e/stack.sh`), the C# journeys (`Backend/Test/PAO.E2ETests`, `Category=Journey`), then the app journeys (`Frontend/test/e2e/run.sh`) |
| `./pao test all` | CLI and Flutter unit → backend unit + integration → e2e |
| `./pao cover` | enforces 100% (backend and every Flutter package), writes `out/coverage/summary.md` |
| `./pao security` | gitleaks (`infra/security/gitleaks.toml`), osv-scanner over the Dart and NuGet lockfiles (`infra/security/osv-scanner.toml`), trivy 0.64.1 (pinned image) over the source tree and, when `PAO_SCAN_IMAGE` is set, the backend image (`infra/security/trivyignore`) |
| `./pao ci` | lint → ops check → gen check → test all → cover → `pao perf e2e` → security (what CI runs) |
| `./pao dotnet [stage]` | one stage of `Backend/scripts/ci.sh` (build, format, spec, gates, unit, test, e2e; `ci` = all) |
| `./pao phase finish <id>` | `ci`, push branch with retry, open PR via `gh`, print the PR URL |
| `./pao perf [e2e]` | the C# load tests (`Backend/Test/PAO.LoadTests`) against the local stack, or a fresh e2e stack |

Implementation rules for the script: `set -euo pipefail`, one function per command,
under 250 lines (helpers in `tools/lib/*.sh`), `shellcheck` clean, and tested by
`tools/cli/pao_test.bats` (bats-core) for argument handling and exit codes.

## 4. Git hooks (installed by `./pao setup`)

| Hook | Runs | Budget |
|---|---|---|
| `commit-msg` | Conventional Commit format check | < 1 s |
| `pre-commit` | file sizes and shellcheck; `./pao lint backend` when `Backend/` is staged; Dart lint + tests and bats when those areas are staged | < 90 s |
| `pre-push` | `./pao ci` (skipped only when the env var `PAO_SKIP_HOOK=1` is set by the CLI itself after it already ran `ci`) | full |

## 5. CI (GitHub Actions)

Workflows in `.github/workflows/`, all required for merging into `main`:

- `backend.yml`: job `dotnet` runs `Backend/scripts/ci.sh all` (build, format, spec,
  gates, unit + integration tests against Postgres+PostGIS, Redis and RustFS service
  containers, the 100% coverage gate, start-up smoke tests); job `tooling` runs
  shellcheck, `./pao ops check`, the CLI tests and `./pao security` (gitleaks,
  osv-scanner, trivy on the source tree and the built backend image).
- `frontend.yml`: format, analyze, unit/widget tests with coverage per package, web build
  of admin, Android debug build of both apps.
- `e2e.yml`: Docker stack + the C# API journeys and the backup restore drill; C# load-test thresholds on a fresh
  stack; the app journeys per app (partner and customer on the Linux desktop, admin in
  Chrome).
- `contract.yml`: OpenAPI lint (`redocly lint Backend/Api/openapi.yaml`), generated code is
  up to date (spec bundle, Dart client, l10n).

Branch protection on `main`: PR required, all four workflows green, linear history
(squash merge).
