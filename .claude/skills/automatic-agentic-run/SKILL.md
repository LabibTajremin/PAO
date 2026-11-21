---
name: automatic-agentic-run
description: Run the remaining PAO build phases (P18 onwards) unattended. Repo copy; it overrides the global skill of the same name.
---

# Automatic agentic run — PAO

Run every phase that is not `done` in `docs/build/PROGRESS.md`, in order, with no human in the
loop. State lives in git and `docs/build/PROGRESS.md` only, so a cut-off session resumes cleanly.

## Where things are

- Rules: `CLAUDE.md` (read fully), `docs/build/00-START-HERE.md`, `01-conventions.md`, `03-testing.md`.
- Requirements and decisions for this round: `docs/build/06-update-2026-11.md` (wins over phase files).
- Phases: `docs/build/phases/P18-*.md` … `P28-*.md`.
- State: `docs/build/PROGRESS.md`. Its **first line** is the machine-read status. Insert it above
  the title on the first run: `RUNNING`, later `ALL_PHASES_DONE <sha>` or
  `BLOCKED: <phase> — <reason> — <what the owner must do>`.

## 1. Preflight (once, before P18)

Check each for real (a harmless live call), list what is missing in one message, wait for the
answer, re-check, then never ask again. Declined = skip the work that needs it and log it under
`## Skipped` in PROGRESS.md.

| Need | Check | Needed by |
|---|---|---|
| git push to `claude/update-2026-11` | `git push --dry-run` | all phases |
| `gh` with `repo`, `workflow` | `gh auth status`, `gh workflow list` | PRs, CI |
| .NET 10 SDK, Flutter 3.47.x, Node (npx), Docker | `dotnet --version`, `flutter --version`, `docker ps` | `./pao ci`, `./pao up` |
| Android emulator / iOS simulator | `flutter devices` | P18, P21, P24 checks (else widget/golden tests only; log it) |
| osmium, planetiler (Java 21) | `osmium --version`, `java -version` | P26 |
| Internet to download.geofabrik.de | `curl -I` | P26 (tests use the fixture extract) |
| Firebase project + a test device | owner confirms | P18 manual heads-up check only |
| Low-end Android phone (2–3 GB RAM) on USB, or an emulator | `adb devices` | P27 perf test (emulator fallback; log the manual check) |

Real Firebase, S3 and SMS are **not** required: tests use the existing fakes. Write
`Preflight: done <date>` with the granted/skipped list in PROGRESS.md, commit, then start.

## 2. Quality gate (every phase, non-negotiable)

`./pao ci` green locally and in CI: lint, architecture rules, unit, integration and e2e,
100% coverage of hand-written code (the repo's existing gate), zero analyzer warnings, build
succeeds. Never cheat to green: no skips, no new coverage exclusions, no weakened assertions or
lowered thresholds, no disabled checks. Unreachable code is deleted.

## 3. Session start

1. `git status`, `git log -3`, read PROGRESS.md top and `## Current task`.
2. `ALL_PHASES_DONE` → report and stop. `BLOCKED` → report and stop. No `Preflight: done` → §1.
3. Resume at the first unchecked task of the `in_progress` (or first `todo`) phase. Uncommitted
   work from a cut-off session: run tests, keep what passes, continue.

## 4. Git flow: one branch, one PR for all phases (owner's rule)

The owner's instruction for this round, and it overrides the per-phase branch/merge flow in
`00-START-HERE.md` §3–4:

- **All of P18–P28 is built on one branch, `claude/update-2026-11`.** Never create
  per-phase branches, never commit to `main`, never push to `main`.
- **One pull request** from that branch into `main`, titled
  `Update round 2026-11 (P18–P28)`. Open it (as a draft) with the first push if it does not
  exist yet; keep its description listing every phase and its status.
- **Never merge the PR yourself**, never enable auto-merge. The owner merges it after every
  phase is done. When all phases are done, mark it ready for review and stop.
- **The PR must pass every test, always.** Every push must leave all CI checks on the PR
  green. CI runs on the PR's merge with `main`, so green on the PR means green on `main`
  after the merge. A red check is fixed before any new task starts.
- **`main` must not go red after the merge.** Keep the branch current with `main`: before
  each phase and before marking the PR ready, `git fetch origin main` and merge it in
  (`git merge --no-edit origin/main`, never rebase or force-push), then run `./pao ci`. Do not
  depend on anything that only exists on the branch's CI run (secrets, caches, manual steps).

```
git fetch origin && git switch claude/update-2026-11   (create from origin/main if missing)
git merge --no-edit origin/main && ./pao ci            (start of each phase)
for each task: TDD → ./pao ci → update PROGRESS.md (same commit) → commit → push
  → gh run watch --exit-status on the PR's checks
     red   → gh run view --log-failed → fix → push → watch     (repeat)
phase done: mark it `done` in PROGRESS.md and in the PR description,
            commit "chore(progress): complete <id>" → push → checks green → next phase
```

A phase is `done` when its tasks are committed and pushed with `./pao ci` green locally
and every PR check green; it is not merged on its own.

Conventional Commits, one task per commit, never force-push, never commit secrets. External
services are reached through ports; tests use fakes. Design tasks (illustrations, icons) are
done by writing SVG and reviewing the rendered PNG at full and phone size before committing.

## 5. BLOCKED

After 6 fix rounds on the same failure: write the `BLOCKED:` first line, commit, push, stop.

## 6. Finish

All phases done (skipped ones excluded): merge the latest `origin/main` into the branch, run
`./pao ci`, set the first line to `ALL_PHASES_DONE <sha>`, commit, push, wait for every PR check
to pass, mark the PR ready for review, stop. Do not merge it: the owner does.
Final report in 10 lines or fewer: phases, coverage, CI link, what was skipped and which
permission would unlock it, decisions worth reading.

## 7. Token economy

`rg` before opening files, open line ranges, edit instead of rewriting, run affected tests while
iterating and the full gate at phase end, report 10 lines or fewer per phase.
