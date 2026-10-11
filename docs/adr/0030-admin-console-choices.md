# ADR-0030: Admin console choices

- Status: Accepted
- Date: 2026-10-11
- Source: docs/build/phases/P13-admin-web.md

## Context

Building the admin web panel surfaced constraints the phase file and the API do not
settle, and several places where the API gives the console less than it needs.

## Decision

- **Session in memory, refresh by cookie.** The access token is never stored by the
  browser; a reload calls `/v1/auth/refresh` with the HttpOnly cookie. An invited admin
  is held on the password page by a router gate until the temporary password is
  replaced.
- **Permission-driven console.** Menu sections follow screen IDs; actions inside a
  screen follow permission strings (e.g. suspend needs `provider:manage`, documents
  need `verification:docs:view`). Catalog editing is gated by the screen itself, since
  only `catalog:manage` reaches it.
- **Shared console widgets.** `PagedTable` + `FilterBar` for every list, a side
  `DetailPanel`, and `confirmWithReason` for destructive actions whose API takes a
  reason; actions whose API takes none (settings, roles, deactivating an admin) use a
  plain confirmation.
- **Verification review.** Documents open on demand through signed URLs (each view is
  audited, so nothing loads automatically) with zoom and 90° rotation; keyboard
  shortcuts A, R and N, and arrows to move between items. "Next provider" opens the
  oldest queued provider other than the current one.
- **Bookings monitor** refreshes every 30 s while open, quietly, dropping a result whose
  filter changed meanwhile.
- **Prices take effect at once.** `PriceInput` has no effective date; the drawer states
  that existing bookings keep their price.
- **Dhaka days.** Date filters are chosen as Asia/Dhaka days and sent as UTC instants.
- **Duplicated icon map.** The catalog icon-key map mirrors the customer app's; it moves
  to a shared package if a third copy appears.

## API gaps (follow-ups)

- Level 2 sessions carry no checklist and verifiers lack `catalog:read`, so only super
  admins get a pre-filled checklist; sessions and complaints carry IDs without names,
  so the console resolves or abbreviates them.
- The verification queue cannot filter by service for verifiers (no service list).
- `listAdminBookings` has no provider or customer filter.
- Complaint evidence photos have no signed-URL endpoint for support agents; the console
  lists them without previews.
- Assigning a complaint to another agent needs `admin_user:manage` to list agents.
- There is no single-service admin read; the editor loads the admin catalog.

## Consequences

The API gaps are recorded for the P15 hardening backlog. The P14 phase owns the Patrol
web journey (verifier approves a provider to Level 1) with the other apps' journeys.
