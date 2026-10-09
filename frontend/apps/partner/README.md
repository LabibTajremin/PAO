# PAO Partner (`apps/partner`)

The provider app (PRD §7.2, §8.2). Screens are listed in `docs/build/05-screens.md`.

## Layout

```
lib/
  app/          services, verification gate, routes, router, tab shell
  features/<f>/
    domain/       repository interface and small value types (no Flutter, no Dio)
    data/         the repository on `pao_api` (generated client) + `AppServices.api`
    presentation/ cubits (flutter_bloc) and pages
  shared/       app-wide helpers (l10n access, uploads)
  l10n/         partner strings (partner_en.arb / partner_bn.arb → PartnerL10n)
```

`features/auth` is the reference feature: copy its shape.

## Rules

- Pages take `AppServices` and build their cubit with the API repository; cubits take
  the domain interface so they are tested with a hand-written fake.
- Every page renders loading, empty, error and offline states. Use `LoadCubit` +
  `ViewStateView` from `pao_core` for screens that load one thing; `attempt()` for
  actions, showing `context.failureText(failure)`.
- Strings go in both ARB files with an `@key` description; run `flutter gen-l10n`.
  Shared strings (buttons, errors) come from `context.common` (pao_l10n).
- Navigation uses `Routes` helpers (`Routes.job(id, 'live')`), never string literals.
- Tests: cubits with fakes (no `bloc_test`: it conflicts with the workspace's analyzer
  version); pages through `Harness` (`test/support/harness.dart`), which mocks the API
  with `http_mock_adapter` and records request bodies (`h.bodyOf(path)`). Await real
  I/O with `h.settle(tester)`; never `pumpAndSettle` alone after an HTTP call.
- 100% line coverage of `lib/` (generated l10n and `main.dart` excluded), files ≤ 200
  lines, functions ≤ 40 lines, `dart analyze --fatal-infos` and `dart_code_linter`
  metrics clean.
