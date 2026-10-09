# Engineering conventions

PAO is built by AI and maintained by humans (PRD §10). Code must read as if a careful
senior engineer wrote it. These rules are enforced by linters and review; CI fails on
violations.

## 1. Size and shape

| Limit | Go | Dart | Enforced by |
|---|---|---|---|
| Lines per source file | 250 | 200 | `./pao lint` (file-length check) |
| Lines per test file | 400 | 300 | `./pao lint` |
| Lines per function | 40 | 40 | `funlen` / `dart_code_linter` |
| Cyclomatic complexity | 10 | 10 | `gocyclo` / `dart_code_linter` |
| Nesting depth | 3 | 3 | `nestif` / review |
| Parameters per function | 4 (else a struct) | 4 (else named params) | review |

When a file approaches its limit, split by responsibility (e.g. `booking_accept.go`,
`booking_cancel.go`), never by arbitrary halves.

## 2. Naming

- Names carry meaning: `AcceptBooking`, `providerID`, `ErrBookingAlreadyAccepted`.
- Banned names: `data`, `info`, `helper`, `utils`, `common`, `misc`, `manager`, `stuff`,
  `temp`, numbered variants (`utils2`).
- Go: package names are short, lowercase, singular nouns (`booking`, `postgres`).
  Errors are `ErrXxx` sentinels in `domain/errors.go`.
- Dart: files `snake_case.dart`, classes `PascalCase`, one public widget per file.
- Feature folders mirror product language from `docs/domain-glossary.md`.

## 3. Comments

- Every exported Go identifier and public Dart API has a doc comment that states its
  purpose or contract in one or two sentences.
- Inside functions, comment only *why*: a business rule (cite the PRD section, e.g.
  `// PRD §5: cancellation is allowed until the start code is entered.`), a non-obvious
  trade-off, or a workaround with an issue link.
- Forbidden: restating code, banner comments, commented-out code, AI narration
  ("Here we…", "Now let's…", "Step 1"), and `TODO` without an issue reference.

## 4. Go specifics

- Go 1.23+. Standard library first; approved libraries only (see `02-architecture.md` §3).
- `context.Context` is the first parameter of anything that does I/O.
- Errors: wrap with `fmt.Errorf("accept booking %s: %w", id, err)`. Map to API error
  codes only in `adapter/http`. Never `panic` outside `main`.
- No package-level mutable state. Dependencies are passed in through constructors.
- Interfaces are declared by the consumer (in `port/`), kept small (1–4 methods).
- SQL lives only in `adapter/postgres`, written as `sqlc` queries.
- Time comes from an injected `Clock`; randomness from an injected source. Both are
  faked in tests.
- Money is `int64` paisa (1 BDT = 100 paisa). Never floats.
- Formatting: `gofmt`, `goimports`. Linting: `golangci-lint` with the committed
  `.golangci.yml`.

## 5. Dart / Flutter specifics

- Dart 3, Flutter stable. Null-safety, `final` by default, no `dynamic`.
- State management: `flutter_bloc` (ADR-0004). One Bloc/Cubit per screen or feature;
  UI never calls repositories directly.
- Layers per feature: `data/` (repositories, DTO mapping) → `domain/` (entities, use
  cases) → `presentation/` (blocs, pages, widgets).
- Widgets: split any `build` method over ~60 lines into private widgets. No business
  logic in widgets.
- All strings come from `pao_l10n` (English + Bangla). No hard-coded user-facing text.
- All colours, spacing and type come from `pao_ui` tokens. No hex literals in apps.
- Formatting: `dart format`. Linting: `flutter analyze` with the committed
  `analysis_options.yaml` (`very_good_analysis` + project rules).

## 6. Git

- Branches: `phase/<id>-<slug>` for phases, `fix/<slug>` for fixes after the build.
- Commits: Conventional Commits, imperative mood, ≤ 72-character subject.
  Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`, `ci`, `build`, `perf`.
- One logical change per commit; tests in the same commit as the code they cover.
- Never commit generated build output, `.env` files, keys or local databases.

## 7. Documentation that must stay current

- `README.md` (root): what PAO is, one-command local run, folder map.
- `backend/internal/modules/<module>/README.md`: responsibility, contract methods,
  events published/consumed, tables owned. Updated in the same commit as the change.
- `docs/adr/NNNN-title.md`: one per significant decision (template in P00).
- `api/openapi.yaml`: updated before the handler that implements a change.
