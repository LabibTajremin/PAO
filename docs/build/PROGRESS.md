# Build progress

The agent updates this file in the same commit as each finished task. A new session reads
it first and continues from **Current task**.

## Status

| Phase | Status | PR | Notes |
|---|---|---|---|
| P00 Bootstrap | done | — | single-branch build, see ADR-0009 |
| P01 Contracts | in_progress | — | |
| P02 Backend platform | todo | — | |
| P03 Identity & access | todo | — | |
| P04 Catalog, media, audit, settings | todo | — | |
| P05 Customer | todo | — | |
| P06 Provider & verification | todo | — | |
| P07 Discovery & booking | todo | — | |
| P08 Rating, notification, complaints | todo | — | |
| P09 Admin API | todo | — | |
| P10 Flutter foundation | todo | — | |
| P11 Partner app | todo | — | |
| P12 Customer app | todo | — | |
| P13 Admin web | todo | — | |
| P14 End-to-end | todo | — | |
| P15 Hardening & handover | todo | — | |

Status values: `todo` → `in_progress` → `in_review` (PR open) → `done` (merged).

## Current task

P01 / task 1 — write `api/openapi.yaml` (split into `api/paths/` and `api/schemas/`).

Branch: all phases are built on `claude/zealous-davinci-78ogmu` (the only branch this
build environment may push to; ADR-0009). A phase is "done" when its tasks are committed
with `./pao ci` green and a `chore(progress): complete <id>` commit is pushed.

## Environment notes

- Go 1.27 (stdlib vulnerabilities in ≤ 1.26.8), golangci-lint v2.14, Flutter 3.47.7.
- Local S3 is RustFS (ADR-0007); MinIO images are no longer published.
- Docker Hub rate-limits pulls here; `mirror.gcr.io/library/<image>` works as a mirror.
- No Android SDK in the build container: APK builds run only in CI (`frontend.yml`).
- Go integration tests live beside the code with the `integration` tag (ADR-0008).

## Blockers

None.

## Log

Newest first. One line per finished task: `YYYY-MM-DD P00.1 short description (commit sha)`.

- 2026-10-09 P00 bootstrap: skeleton, Go module + healthz, Flutter workspace, Docker
  stack, `pao` CLI + bats tests, hooks, coverage gate, CI workflows, docs and ADRs.
