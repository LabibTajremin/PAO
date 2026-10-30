# Engineering conventions

PAO is built by AI and maintained by humans (PRD §10). Code must read as if a careful
senior engineer wrote it. These rules are enforced by linters and review; CI fails on
violations.

## 1. Size and shape

| Limit | C# | Dart | Enforced by |
|---|---|---|---|
| Lines per source file | 250 | 200 | C#: `SizeChecker` gate (`./pao lint backend`); Dart: `./pao lint` file-length check |
| Lines per test file (`Backend/Test/**`, Dart `test/`, `integration_test/`) | 400 | 300 | same |
| Lines per method or function | 40 | 40 | `SizeChecker` / `dart_code_linter` |
| Cyclomatic complexity | 10 | 10 | review / `dart_code_linter` |
| Nesting depth | 3 | 3 | review |
| Parameters per function | 4 (else a request or options type) | 4 (else named params) | review |

Generated code (`*.gen.*`, `*.g.cs`, `pao_api`, l10n output) is exempt. When a file
approaches its limit, split by responsibility (one feature folder per use case), never
by arbitrary halves.

## 2. Naming

- Names carry meaning: `acceptBooking`, `providerId`, `booking.already_accepted`.
- Banned names: `data`, `info`, `helper`, `utils`, `common`, `misc`, `manager`, `stuff`,
  `temp`, numbered variants (`utils2`).
- Dart: files `snake_case.dart`, classes `PascalCase`, one public widget per file.
- Feature folders mirror product language from `docs/guides/domain-glossary.md`.

## 3. Comments

- Every public C# type and member (XML docs; CS1591 is an error outside `Test/`) and every
  public Dart API has a doc comment that states its purpose or contract in one or two sentences.
- Inside functions, comment only *why*: a business rule (cite the PRD section, e.g.
  `// PRD §5: cancellation is allowed until the start code is entered.`), a non-obvious
  trade-off, or a workaround with an issue link.
- Forbidden: restating code, banner comments, commented-out code, AI narration
  ("Here we…", "Now let's…", "Step 1"), and `TODO` without an issue reference.

## 4. C# / .NET specifics (ADR-0034)

The binding rules, layout and "adding a feature" recipe are in
[`Backend/PAO.AI/README.md`](../../Backend/PAO.AI/README.md); the reference is `Backend/Docs/`.
In short:

- .NET 10, C# latest, nullable references, analyzers and warnings as errors
  (`Backend/Directory.Build.props`); every package version pinned in
  `Directory.Packages.props`. Only MIT, Apache-2.0 or BSD packages; anything new needs an ADR.
- One ASP.NET area per module; an area reaches another only through its shared service.
  One use case = one feature folder with its command or query, validator and handler.
- Request models in, view models out, db models in `PAO.EF`, converted by a hand-written
  mapper. FluentValidation for requests. No database calls in loops.
- Every controller action carries an authorisation attribute matching the spec's
  `x-permission`; architecture tests enforce the rules above.
- Errors: handlers fail with a module-scoped reason (`booking.already_accepted`); only the
  HTTP edge maps reasons to API errors. Time from the injected clock, ids from the
  injected id generator. Money is integer paisa (`long`).
- Formatting: `dotnet format` (`Backend/.editorconfig`), checked by `./pao lint backend`.

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
- `Backend/Docs/Areas/<Area>/` (overview, features, endpoints, data, events): updated in
  the same commit as the change; the docs gate fails on a missing page or broken link.
- `docs/adr/NNNN-title.md`: one per significant decision (template in P00).
- `Backend/Api/openapi.yaml`: updated before the handler that implements a change.
