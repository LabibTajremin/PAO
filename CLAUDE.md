# PAO — agent rules

You are building PAO, a home-services marketplace for Bangladesh: Go backend, Flutter apps.
These rules apply to every session. Read them fully; they are short on purpose.

## Where things are

| Need | File |
|---|---|
| How the build runs, phase order, git flow, resume | `docs/build/00-START-HERE.md` |
| Current state — **read this first, every session** | `docs/build/PROGRESS.md` |
| Code rules (size limits, comments, naming) | `docs/build/01-conventions.md` |
| Architecture, Redis, RBAC, security | `docs/build/02-architecture.md` |
| Test strategy, coverage gates, `pao` CLI | `docs/build/03-testing.md` |
| Decisions on PRD open questions | `docs/build/04-decisions.md` |
| Screen list mapped to Figma | `docs/build/05-screens.md` |
| The phase you are working on | `docs/build/phases/PNN-*.md` |
| Product requirements (plain text) | `docs/prd/PAO-PRD.txt` |

## Non-negotiables

1. Work only on the phase marked `in_progress` in `PROGRESS.md`. Never skip ahead.
2. A task is done only when `./pao ci` passes locally: lint, architecture rules, unit,
   integration and e2e tests, and 100% coverage of hand-written code.
3. Never weaken a gate to get green: no deleting tests, no `//nolint` without a reason,
   no new coverage exclusions, no `skip`. Fix the code instead.
4. Never commit secrets. Configuration comes from environment variables only.
5. Update `PROGRESS.md` after every completed task, then commit. It is how the next
   session resumes.
6. Keep files small (Go ≤ 250 lines, Dart ≤ 200 lines, functions ≤ 40 lines). Split
   instead of growing.
7. Comments explain *why*, never *what*. No AI narration ("Here we…", "Step 1").
8. When the PRD and these docs disagree, the PRD wins for behaviour and these docs win
   for engineering. If both are silent, use `04-decisions.md`, then record a new ADR.

## Token discipline

- Read only what the current task needs: its phase file, the PRD section it cites and the
  module README. Do not re-read files you have already read in this session.
- Search with `rg` or Grep before opening files; open line ranges, not whole files.
- Prefer generators (`sqlc`, `oapi-codegen`, OpenAPI Dart client) over hand-written
  boilerplate.
- Do not paste long command output into your notes. Summarise failures in one line.
