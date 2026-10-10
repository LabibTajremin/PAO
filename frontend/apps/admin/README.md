# PAO Admin (`apps/admin`)

The operations web panel (Flutter Web; PRD §6, §7.3, §8.3). Screens and the permission
each needs are listed in `docs/build/05-screens.md`.

## Layout

```
lib/
  app/          services, routes, router (sign-in guard + password gate), console shell, menu
  features/<f>/
    domain/       repository interface and small value types (no Flutter, no Dio)
    data/         the repository on `pao_api` (generated client) + `AppServices.api`
    presentation/ cubits (flutter_bloc) and pages
  shared/       paged table, filter bar, detail drawer, confirm-with-reason dialog, l10n
  l10n/         admin strings (admin_en.arb / admin_bn.arb → AdminL10n)
```

`features/auth` is the reference feature. Screens still being built show
`PlaceholderPage`; replace the entry in `app/pages.dart` when one lands.

## Rules

- The access token lives only in memory; a reload restores the session from the
  HttpOnly refresh cookie (`restoreSession`). An invited admin replaces the temporary
  password before the console opens.
- The menu shows a section only when `permissions.canSee(screenId)`; the router guard
  blocks the rest. Hide actions the admin's permissions do not allow.
- Lists are `PagedCubit` + `PagedTable` with a `FilterBar`; destructive actions ask for
  a reason with `confirmWithReason`.
- Wide screens (≥ 1024 px) show the menu as a sidebar, narrower ones as a drawer.
- Strings go in both ARB files with an `@key` description, keys prefixed by feature.
- Tests: cubits with fakes; pages through `Harness` (`test/support/harness.dart`),
  `desktop(tester)` or `narrow(tester)` first. 100% line coverage of `lib/` (generated
  l10n and `main.dart` excluded), files ≤ 200 lines, functions ≤ 40 lines.
