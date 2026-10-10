# PAO (`apps/customer`)

The customer app (PRD §7.1, §8.1). Screens are listed in `docs/build/05-screens.md`.

## Layout

```
lib/
  app/          services, profile gate, routes, router, tab shell
  features/<f>/
    domain/       repository interface and small value types (no Flutter, no Dio)
    data/         the repository on `pao_api` (generated client) + `AppServices.api`
    presentation/ cubits (flutter_bloc) and pages
  shared/       app-wide helpers (l10n access, uploads, formats)
  l10n/         customer strings (customer_en.arb / customer_bn.arb → CustomerL10n)
```

`features/auth` is the reference feature: copy its shape. Choices specific to this app
(maps port, polling, start-code protection, receipt PDF) are in ADR-0029.

## Rules

- Pages take `AppServices` and build their cubit with the API repository; cubits take
  the domain interface so they are tested with a hand-written fake.
- Every page renders loading, empty, error and offline states. Use `LoadCubit` +
  `ViewStateView` (one thing) or `PagedCubit` + `PagedView` (a cursor list) from
  `pao_core`; `attempt()` for actions, showing `context.failureText(failure)`.
- Strings go in both ARB files with an `@key` description, keys prefixed by feature;
  run `flutter gen-l10n`. Shared strings (buttons, errors) come from `context.common`.
- Navigation uses `Routes` helpers (`Routes.booking(id, 'live')`), never literals.
- A new account has no profile: the router's profile gate keeps it on set-up (C05).
- Tests: cubits with fakes (no `bloc_test`); pages through `Harness`
  (`test/support/harness.dart`), which mocks the API with `http_mock_adapter` and
  records request bodies (`h.bodyOf(path)`). Await real I/O with `h.settle(tester)`.
- 100% line coverage of `lib/` (generated l10n and `main.dart` excluded), files ≤ 200
  lines, functions ≤ 40 lines, `dart analyze --fatal-infos` and `dart_code_linter`
  metrics clean.
