# P00 — Bootstrap

**Goal:** an empty-but-working repository: every tool, gate and pipeline exists before any
feature code, so all later phases are measured from the first commit.

**Read first:** PRD §9.4, §9.5, §10; `01-conventions.md`; `03-testing.md`.

## Tasks

0. **Main branch.** If `origin/main` does not exist, create `main` from the commit that
   added `docs/build/` and push it. Then branch `phase/P00-bootstrap` from `main`.
1. **Skeleton.** Create the tree from `02-architecture.md` §1 with placeholder
   `README.md` files that state each folder's purpose. Add `.gitignore`,
   `.editorconfig`, `.env.example` (every variable documented, no real values),
   `LICENSE` placeholder (owner decides; mark "All rights reserved").
2. **Go module.** `backend/go.mod` (`module github.com/LabibTajremin/PAO/backend`),
   `cmd/api/main.go` serving `GET /healthz` → `{"status":"ok"}`, `cmd/worker/main.go`
   that starts and stops cleanly. `.golangci.yml` with: `errcheck, govet, staticcheck,
   gosec, revive, funlen(40), gocyclo(10), nestif(3), gocritic, misspell, unparam,
   bodyclose, sqlclosecheck, depguard`. `.go-arch-lint.yml` encoding PRD §9.3.
3. **Flutter workspace.** `frontend/melos.yaml`; create `apps/customer`, `apps/partner`,
   `apps/admin` (web) and `packages/pao_core`, `pao_ui`, `pao_l10n` (`pao_api` arrives in
   P01). Each app shows a placeholder screen. Shared `analysis_options.yaml` using
   `very_good_analysis` plus `dart_code_linter` metrics from `01-conventions.md` §1.
4. **Docker stack.** `docker-compose.yml`: `postgis/postgis:16-3.4`, `redis:7-alpine`,
   `minio/minio`, `api`, `worker`; health checks on every service.
   `backend/Dockerfile`: multi-stage, distroless, non-root user.
5. **`pao` CLI.** Implement every command in `03-testing.md` §3 (commands whose targets
   don't exist yet must succeed with "nothing to run"). `shellcheck` clean.
   Tests: `test/cli/pao_test.bats`.
6. **Git hooks.** `scripts/hooks/{commit-msg,pre-commit,pre-push}` installed by
   `./pao setup` (`git config core.hooksPath scripts/hooks`).
7. **Coverage tooling.** `.testcoverage.yml` (go-test-coverage, threshold 100,
   exclusions from `03-testing.md` §2), `.coverage-exclude`, Dart `coverage_exclude`.
   Prove the gate works: the healthz handler has a test; removing it must fail `./pao cover`.
8. **CI.** The four workflows from `03-testing.md` §5. Cache Go modules, pub cache and
   Docker layers. Pin action versions by SHA.
9. **Docs.** Root `README.md` (what PAO is, `./pao setup && ./pao up`, folder map),
   `CONTRIBUTING.md` (branches, commits, PR checklist), `docs/architecture.md` (summary +
   link to `02-architecture.md`), `docs/domain-glossary.md` (booking, sub-service, level,
   start code, extra item, service model, presence), `docs/adr/0000-template.md`, and
   ADRs 0001–0006 plus one ADR per row of `04-decisions.md` product defaults.

## Definition of done

- `./pao setup && ./pao ci` passes on a clean clone.
- `docker compose up` brings every service to healthy; `curl :8080/healthz` returns ok.
- All three Flutter apps build (`flutter build apk --debug`, `flutter build web`).
- CI is green on the PR; the PR is merged.
