# ADR-0029: Customer app choices

- Status: Accepted
- Date: 2026-10-10
- Source: docs/build/phases/P12-customer-app.md

## Context

Building the customer app surfaced constraints the phase file and the API do not
settle. The partner app's choices (ADR-0028: cubit tests without `bloc_test`, dates as
strings, Patrol journeys in P14) apply here too.

## Decision

- **Profile gate.** A new account has no customer profile (`GET /v1/customer/profile`
  is 404); the router keeps it on profile set-up (C05) until one is saved. Other
  failures keep the last answer so being offline never locks a customer out.
- **Booking draft in the query.** The service, items, provider and driver-hire start
  travel from C09 to C12 as query parameters (`BookingDraft`), so a restored or
  deep-linked screen keeps the selection.
- **Maps port without a native map.** `PlacesService` (D10) has a Google Geocoding
  adapter keyed by `--dart-define=PAO_MAPS_API_KEY`; without a key search returns
  nothing and the address is typed. The pin is dragged on a `PaoMapFrame` instead of
  `google_maps_flutter`, which needs native key set-up; a real map can replace it
  behind `AppServices.places` later. Without a device position the pin starts in
  central Dhaka. The area check never blocks saving; the API checks again.
- **Nearby search uses the first item.** `findNearbyProviders` takes one sub-service,
  so a multi-item draft searches by its first item and shows the price summary only
  for a single item. Multi-item search needs an API change.
- **Polling instead of foreground push.** `PushService` exposes token and tap streams
  only, so waiting and live screens poll the booking every 5 s; a failed poll keeps the
  last booking marked stale. Push taps are routed to the matching booking screen.
- **Idempotent create.** One random key per confirmation, reused while the request body
  is unchanged and replaced when timing, address, items or note change.
- **Scheduling window.** A scheduled time is 1 hour to 30 days ahead (the PRD is
  silent; 1 hour covers the 30-minute accept window, D12, plus travel). Pickers work in
  Asia/Dhaka wall time and send UTC; driver hire has no ASAP.
- **Start code protection.** Screenshots are blocked with `FLAG_SECURE` through a
  `pao/secure_screen` method channel in `MainActivity` while the code is visible (no
  plugin for one window flag; no effect on iOS). The code is cached in `Prefs` for
  offline display and blanked once the job has started.
- **Receipt PDF in English.** `pdf` + `share_plus` build and share it behind an
  injectable seam. The built-in PDF fonts cannot shape Bengali, so the PDF is English
  with amounts as "BDT"; a Bangla PDF needs a bundled font and is deferred.
- **Account deletion.** The OTP goes to the phone from `GET /v1/me`; after `deleteMe`
  the app opens the public goodbye screen and signs out locally without calling
  logout, since deletion already revokes the tokens.
- **Support contacts and legal text from the build.** `PAO_SUPPORT_PHONE` and
  `PAO_SUPPORT_EMAIL` set the help contacts (placeholders until operations supply
  them). The terms, privacy and FAQ text is a draft that needs legal review.

## Consequences

The terms, privacy and FAQ copy, the support contacts and a Maps API key are launch
prerequisites. A native map, Bangla receipts and multi-item provider search are
follow-ups. App journeys for this app are written in P14 with the other apps'.
