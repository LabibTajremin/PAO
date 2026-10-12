# Engineering conventions

PAO is built by AI and maintained by humans (PRD §10). Code must read as if a careful
senior engineer wrote it. These rules are enforced by linters and review; CI fails on
violations.

## 1. Size and shape

| Limit | TypeScript | Dart | Enforced by |
|---|---|---|---|
| Lines per source file | 250 | 200 | `./pao lint` (file-length check), ESLint `max-lines` |
| Lines per test file | 400 | 300 | `./pao lint` |
| Lines per function | 40 | 40 | ESLint `max-lines-per-function` / `dart_code_linter` |
| Cyclomatic complexity | 10 | 10 | ESLint `complexity` / `dart_code_linter` |
| Nesting depth | 3 | 3 | ESLint `max-depth` / review |
| Parameters per function | 4 (else an options object) | 4 (else named params) | ESLint `max-params` / review |

Generated code (`sqlc/`, `*.gen.*`, `pao_api`, l10n output) is exempt. When a file
approaches its limit, split by responsibility (e.g. `accept-booking.ts`,
`cancel-booking.ts`), never by arbitrary halves.

## 2. Naming

- Names carry meaning: `acceptBooking`, `providerId`, `booking.already_accepted`.
- Banned names: `data`, `info`, `helper`, `utils`, `common`, `misc`, `manager`, `stuff`,
  `temp`, numbered variants (`utils2`).
- Dart: files `snake_case.dart`, classes `PascalCase`, one public widget per file.
- Feature folders mirror product language from `docs/domain-glossary.md`.

## 3. Comments

- Every exported TypeScript class, function, interface and type, and every public Dart
  API, has a doc comment that states its purpose or contract in one or two sentences.
- Inside functions, comment only *why*: a business rule (cite the PRD section, e.g.
  `// PRD §5: cancellation is allowed until the start code is entered.`), a non-obvious
  trade-off, or a workaround with an issue link.
- Forbidden: restating code, banner comments, commented-out code, AI narration
  ("Here we…", "Now let's…", "Step 1"), and `TODO` without an issue reference.

## 4. TypeScript / NestJS specifics (ADR-0032)

- Node.js 22, TypeScript `strict` (+ `noUncheckedIndexedAccess`), NestJS 11 on Express.
  Approved libraries only (ADR-0032); anything else needs an ADR.
- Files `kebab-case.ts`, one use case per file in `app/` (`accept-booking.ts`), classes
  `PascalCase`, functions and variables `camelCase`, constants and injection tokens
  `UPPER_SNAKE_CASE`. Unit specs `*.spec.ts` and integration specs `*.int-spec.ts` sit
  beside the code they test.
- Exported classes, functions, interfaces, types and enums carry a JSDoc comment; the
  same comment rules as §3 apply.
- Dependencies come through constructors (Nest DI). Cross-module dependencies are
  injection tokens from the other module's `contract/`; ports are interfaces in `port/`
  with a token beside them. No module-level mutable state.
- Errors: domain and use cases throw `DomainError` with a module-scoped `reason`
  (`booking.already_accepted`); only `adapter/http` maps reasons to API errors. Wrap
  infrastructure failures with `new Error('accept booking ' + id, { cause })`.
- `async`/`await` only; no floating promises. Time from the injected `Clock`, ids from
  the injected `IdGenerator`.
- Money is integer paisa in a `number` (always `Number.isSafeInteger`); Postgres `bigint`
  arrives as a string from sqlc and is converted in `adapter/postgres`.
- Ids are UUID strings; times are `Date` inside the app and ISO-8601 strings in JSON and
  event payloads.
- SQL only in `adapter/postgres`, through sqlc-generated functions from the module's
  `queries.sql`; parameters only, never string-built SQL.
- Formatting: Prettier. Linting: `npm run lint` (ESLint `strictTypeChecked`, Prettier
  check, dependency-cruiser module rules).

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
- `backend/src/modules/<module>/README.md`: responsibility, contract methods,
  events published/consumed, tables owned. Updated in the same commit as the change.
- `docs/adr/NNNN-title.md`: one per significant decision (template in P00).
- `api/openapi.yaml`: updated before the handler that implements a change.
