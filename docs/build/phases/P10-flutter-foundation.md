# P10 — Flutter foundation

**Goal:** shared packages so the three apps contain only features: networking, sessions,
permissions, design system, translations and routing.

**Read first:** PRD §9.5, §11 (localisation, low-end devices, accessibility);
`05-screens.md` (theme notes); the Figma cover page and variable collections.

## Tasks

1. **pao_core**
   - `Env` (API base URL, flavour) from `--dart-define`; no secrets in the binary.
   - Dio client: base options, timeouts tuned for slow 3G, request ID header, retry for
     idempotent GETs only, error mapping from the API error format to a sealed
     `AppFailure` type with stable codes.
   - `SessionStore` (flutter_secure_storage on mobile, in-memory + cookie on web),
     auth interceptor with single-flight refresh, logout on refresh failure → C63.
   - `PermissionService`: loads `/v1/me/permissions`, exposes `canSee(screenId)` and
     `can(permission)`, refreshes on token refresh.
   - Router helpers: `go_router` redirect guard that checks auth and screen IDs, plus the
     provider verification gate.
   - Connectivity watcher (drives the C36 offline banner), image compression before upload.
2. **pao_api** — generated client from P01; a thin hand-written `Repository` per feature
   lives in each app's `data/` layer (not in `pao_api`).
3. **pao_ui**
   - Tokens: colours mirrored from Figma `Base` + `Accent`, as a `ThemeExtension`
     `PaoColors`; ten `AccentPreset`s (values in `05-screens.md`); spacing (4-pt scale), radii, type scale with Plus
     Jakarta Sans and Hind Siliguri fallback for Bangla and ৳.
   - `PaoTheme.light(accent: AccentPreset.midnight)` — changing the accent re-themes every
     component.
   - Components (one file each, with widget tests and a gallery page in `example/`):
     buttons (primary, soft, outline, ghost, danger), text field, OTP input, chip,
     badge/pill, avatar, icon tile, card, list row, segmented control, stepper,
     status stepper, bottom sheet, empty state, error state, skeleton loader, bottom nav,
     app bar, money text (`৳1,130`), rating stars, map placeholder frame.
   - Accessibility: tap targets ≥ 48 dp, semantic labels, text scaling up to 1.3× without
     overflow (tested).
4. **pao_l10n** — ARB files `en` and `bn` for every string the apps use; plural and money
   formatting helpers; Asia/Dhaka date formatting.

## Tests

Unit tests for every class in `pao_core` (Dio with `http_mock_adapter`), widget tests for
every `pao_ui` component in each state, golden-free (assert widgets and semantics, not
pixels). 100% coverage per package.

## Definition of done

The three apps boot with the theme, language switch and a guarded placeholder route.
`./pao ci` green; PR merged.
