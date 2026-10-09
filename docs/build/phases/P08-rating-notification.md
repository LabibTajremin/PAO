# P08 — Rating, notification, complaints

**Goal:** both sides rate each other, every booking event reaches the right person
within 3 seconds, and problems can be reported.

**Read first:** PRD features C-11, C-13, C-14, P-09, P-12, A-07, §11 (performance).

## Tasks

1. **Rating** — after `BookingCompleted` each side may rate once (1–5 stars, tags from a
   fixed list, optional comment ≤ 500 chars). Aggregates per provider: average, count,
   distribution (incrementally updated). `GetProviderRating` contract; public review
   list with cursor pagination; customer rating aggregate visible to providers (M16).
2. **Notification** — `Send(recipient, template, data)` with channels push (FCM port),
   SMS (OTP and critical only), in-app inbox. Templates in BN and EN for every event in
   `02-architecture.md` §8. Device token registration per app; invalid tokens removed.
   In-app list + mark read + mark all read. Delivery runs from the outbox relay so a
   booking request reaches the provider in < 3 s.
3. **Complaints (admin module)** — customer and provider reports with reason, description,
   photos (media IDs); ticket number; statuses Open → Assigned → Resolved with
   resolution note; publishes `ComplaintResolved`; verified complaints feed the quality
   review (PRD §6.4).

## Tests

- Unit: rating eligibility (only after completion, once per side), aggregate maths,
  template rendering for both languages, complaint status transitions.
- Integration: event → notification rows for each booking event (table test), FCM fake
  receives the payload, inbox pagination, duplicate events do not double-notify.

## Definition of done

`./pao ci` green; PR merged.
