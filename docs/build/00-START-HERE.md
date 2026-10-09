# PAO build — start here

This folder is a complete, phased instruction set for an AI coding agent to build PAO from
an empty repository to a working, tested product: Go API, Flutter customer app, Flutter
partner (provider) app and Flutter Web admin panel.

The agent works autonomously, one phase at a time. Each phase ends with a pull request
whose CI is green, merged into `main`. The build is finished when every phase in the table
below is `done` in `PROGRESS.md`.

## 1. Phases

| # | Phase | Output |
|---|---|---|
| P00 | [Bootstrap](phases/P00-bootstrap.md) | Folders, `pao` CLI, git hooks, CI, Docker stack, lint configs |
| P01 | [Contracts](phases/P01-contracts.md) | `openapi.yaml`, module contracts, events, DB schemas, RBAC matrix |
| P02 | [Backend platform](phases/P02-platform.md) | Config, DB, Redis, HTTP, errors, middleware, event bus, outbox, jobs |
| P03 | [Identity & access](phases/P03-identity.md) | OTP login, JWT + refresh in Redis, RBAC, screen permissions, admin 2FA |
| P04 | [Catalog, media, audit, settings](phases/P04-catalog-media-audit.md) | Versioned catalog + seed, signed uploads, audit log, settings |
| P05 | [Customer](phases/P05-customer.md) | Customer profile, saved addresses (PostGIS) |
| P06 | [Provider & verification](phases/P06-provider-verification.md) | Enrolment, documents, levels, expiry jobs, online status |
| P07 | [Discovery & booking](phases/P07-booking.md) | Nearby search, booking state machine, start code, extras, cancel |
| P08 | [Rating, notification, complaints](phases/P08-rating-notification.md) | Two-way reviews, push/SMS/in-app, complaints |
| P09 | [Admin API](phases/P09-admin-api.md) | Dashboard, user management, bookings monitor, audit viewer |
| P10 | [Flutter foundation](phases/P10-flutter-foundation.md) | Melos workspace, core, API client, design system, l10n, router guards |
| P11 | [Partner app](phases/P11-partner-app.md) | All provider screens, wired to the real API |
| P12 | [Customer app](phases/P12-customer-app.md) | All customer screens, wired to the real API |
| P13 | [Admin web](phases/P13-admin-web.md) | All admin screens (verification first) |
| P14 | [End-to-end](phases/P14-e2e.md) | Full-journey tests across API and apps |
| P15 | [Hardening & handover](phases/P15-hardening.md) | Security and performance pass, docs, release builds |

Phases are strictly sequential. A phase may not start until the previous one is merged.

## 2. Session start (every session, including resumes)

1. Read `CLAUDE.md`, then `docs/build/PROGRESS.md`.
2. `git fetch origin && git status`. If the working tree is dirty, finish or discard the
   half-done task recorded in `PROGRESS.md` → *Current task* before doing anything else.
3. Open the phase file for the phase marked `in_progress` (or the first `todo` one).
4. Continue from the first unchecked task in that phase.

## 3. Working a phase

```
git checkout main && git pull
git checkout -b phase/P07-booking          # branch name: phase/<id>-<slug>
# for each task in the phase file:
#   write code + tests → ./pao ci → update PROGRESS.md → commit
./pao phase finish P07                     # final gate, push, open PR
```

- **One task = one commit** using Conventional Commits:
  `feat(booking): add start-code verification`, `test(catalog): cover price versioning`.
  The scope is the module or app name.
- Commit only after `./pao ci` passes. The pre-commit hook enforces the fast checks.
- `PROGRESS.md` is updated in the same commit as the task it records.

## 4. Finishing a phase: push, PR, green, merge

`./pao phase finish <id>` does steps 1–3. If the CLI cannot reach GitHub in your
environment, do them by hand (or with the GitHub tools you have).

1. Run the full gate (`./pao ci`) one last time.
2. `git push -u origin phase/<id>-<slug>` — on network failure retry with backoff
   2s, 4s, 8s, 16s.
3. Open a PR into `main` titled `<id>: <phase name>`. Body: the phase goal, a task checklist
   copied from the phase file (all ticked) and the coverage summary from `./pao cover`.
4. Wait for CI. If a check fails: read the log, reproduce locally, fix, push. Repeat until
   every check is green. Never merge red.
5. Squash-merge, delete the branch, mark the phase `done` in `PROGRESS.md` on `main` and
   commit `chore(progress): complete <id>`.
6. Start the next phase immediately. Do not stop between phases.

## 5. Pausing and auto-resume

The agent never needs a human between phases. If a usage or rate limit stops it, nothing
is lost, because all state lives in git and `PROGRESS.md`.

**Before you are cut off** (when you notice the limit is close):
commit any passing work, update *Current task* in `PROGRESS.md` with the next concrete
step, and push the branch.

**To resume automatically**, a scheduler re-sends one fixed prompt until the build is done:

> Resume the PAO build. Follow `docs/build/00-START-HERE.md` section 2 exactly. If every
> phase in `docs/build/PROGRESS.md` is `done`, reply "PAO build complete" and stop.

Ways to schedule it:

- **Claude Code (web or CLI):** create a recurring Routine (e.g. every 3 hours) that sends
  the prompt above into the build session, or run `/loop 3h <prompt>` in that session.
- **Any other agent runner:** a cron job that starts a new session with the prompt.

The prompt is idempotent: if a session is already running, the next one finds the same
state in `PROGRESS.md` and continues from it. Delete the schedule after
"PAO build complete".

## 6. When stuck

- A failing test you cannot fix in 3 attempts: write down the root-cause hypothesis in
  `PROGRESS.md` → *Blockers*, try a different approach, and do not disable the test.
- A genuine product question the PRD and `04-decisions.md` don't answer: choose the
  safest option, write an ADR in `docs/adr/` marked `Status: Proposed — needs owner
  review`, and continue. Never stop the build for a question.
- External services (SMS gateway, FCM, NID check, maps keys) are always behind ports with
  a local fake adapter. Missing credentials never block a phase.
