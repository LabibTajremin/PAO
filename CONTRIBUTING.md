# Contributing to PAO

## Branches

- `main` is always releasable and protected; changes arrive through pull requests.
- Feature work after the initial build: `fix/<slug>` or `feat/<slug>`.
- Build phases: `phase/<id>-<slug>` (see `docs/build/00-START-HERE.md`).

## Commits

[Conventional Commits](https://www.conventionalcommits.org), imperative mood, subject
≤ 72 characters. Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`, `ci`,
`build`, `perf`. The scope is the module or app: `feat(booking): add start-code check`.
One logical change per commit, with its tests. The `commit-msg` hook checks the format.

## Before you push

`./pao setup` installs the hooks. `pre-commit` runs lint and unit tests; `pre-push` runs
`./pao ci` (lint, generated-code check, all tests, 100% coverage, security scans).

## Pull request checklist

- [ ] `./pao ci` passes locally.
- [ ] Tests cover the change (coverage stays at 100% of hand-written code).
- [ ] `api/openapi.yaml` was updated before the handler that implements a change.
- [ ] The module `README.md` reflects new contract methods, events or tables.
- [ ] Significant decisions have an ADR in `docs/adr/`.
- [ ] No secrets, `.env` files, build output or commented-out code.
- [ ] Comments explain *why*; code follows `docs/build/01-conventions.md`.
