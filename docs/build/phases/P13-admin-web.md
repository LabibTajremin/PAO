# P13 — Admin web

**Goal:** the operations team can run the platform from `apps/admin` (Flutter Web).
Verification screens first — without them no provider can be onboarded (PRD §12).

**Read first:** PRD §6, §7.3, §8.3; `05-screens.md` admin table; `02-architecture.md` §6.

## Order of work

1. Shell: login + 2FA (A01), responsive layout (sidebar ≥ 1024 px, drawer below),
   permission-driven navigation (menu items hidden when `canSee` is false), session via
   refresh cookie.
2. Verification queue and review (A05, A06): side-by-side document viewer using signed
   URLs, zoom/rotate, NID data panel, face-match result, approve/reject per item with
   reason templates, keyboard shortcuts (A = approve, R = reject, N = next).
3. Level 2 sessions (A07).
4. Catalog tree and service editor (A03, A04) with price history.
5. Providers, customers (A08, A09): search, detail, suspend/ban with reason confirmation.
6. Bookings monitor (A10), complaints (A11).
7. Dashboard (A02), settings, admin users, roles and audit log (A12).

Reusable admin widgets live in `apps/admin/lib/shared/`: data table with cursor
pagination, filter bar, detail drawer, confirm-with-reason dialog.

## Tests

Bloc + widget tests for every page; Patrol web journey: verifier logs in with 2FA,
approves a provider's documents, provider reaches Level 1.

## Definition of done

Every admin screen works against the API with correct permission hiding per role.
`./pao ci` green; PR merged.
