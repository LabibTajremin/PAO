# ADR-0009: Build on one session branch instead of per-phase pull requests

- Status: Proposed — needs owner review
- Date: 2026-10-09
- Source: 00-START-HERE.md §3–4

## Context

The build kit asks for one branch and one squash-merged PR per phase. The automated build environment only permits pushing to a single assigned branch and does not open PRs unless the owner asks.

## Decision

All phases are committed in order on the assigned branch with one Conventional Commit per task. Phase boundaries are marked in `PROGRESS.md` and by `chore(progress): complete <id>` commits. `./pao ci` is still the gate for every commit, and the CI workflows also run on `claude/**` branches.

## Consequences

The owner can open one PR for the whole build, or split it by phase using the phase-completion commits. Phase-level code review is replaced by review of the commit range.
