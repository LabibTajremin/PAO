# P06 — Provider & verification

**Goal:** a provider can enrol, submit documents, be verified to Level 1 or 2, go online
and be found — and loses access automatically when a document expires.

**Read first:** PRD §6 (all), features P-02–P-04, P-10, P-11, A-03, A-04; screens M05–M15b.

## Tasks

1. **Provider domain** — profile (name as on NID, DOB ≥ 18, gender, present/permanent
   address, bio, experience years), services offered (catalog service IDs), home base
   point + working radius, emergency contact (phone verified by OTP), code-of-conduct
   acceptance (version + timestamp), account status (PRD §6.4).
2. **Enrolment** — one endpoint per wizard step (M05–M13), saved after each step,
   resumable; `GET` returns completion per step.
3. **Verification domain** — document types and checks from PRD §6.2 (NID front/back +
   number, live selfie, police clearance with issue date ≤ 12 months, address, emergency
   contact, skill proof optional, service area, code of conduct). Per-item status:
   Pending / Approved / Rejected (reason) / Expired. Level rules (PRD §6.1):
   Level 1 when every required item is approved; Level 2 after a passed Level 2 session.
4. **Sensitive data** — NID number encrypted (AES-256-GCM); documents via media module in
   the private bucket; never exposed on customer APIs (PRD §6.6).
5. **Admin review** — queue with filters and age (A-03), item approve/reject with reason,
   Level 2 session scheduling + checklist + result pass/fail/retest with cooling-off
   (A-04). Every decision → audit entry (who, when, what, why).
6. **Expiry** — jobs from `02-architecture.md` §9: expire documents, drop the level,
   publish `DocumentExpired`, reminders at 30/7/1 days (P-11).
7. **Presence** — online/offline toggle (only if `CanReceiveBookings`), heartbeat with
   location every 30 s while online (Redis GEO per service + heartbeat key), offline on
   heartbeat loss; location is never stored while offline (PRD §11).
8. **Contracts** — `GetProvider`, `GetLevel`, `CanReceiveBookings`, `IsAvailable`,
   `FindNearby(serviceID, point, radius, sort)` returning verified, online, registered
   providers within radius, Level 2 ranked first, then distance or rating (PRD §5).
9. **Quality** — subscriber flags providers for review on rating/cancellation thresholds
   (D13).

## Tests

- Unit: level calculation for every combination of item statuses, expiry date maths,
  enrolment step validation, nearby ranking order.
- Integration: full enrolment, approve all → Level 1 → can go online; reject one →
  re-upload → approve; expiry job drops level and forces offline; `FindNearby` with
  PostGIS + Redis GEO meets the women-only rule for home salon (D11); customer endpoints
  never include document fields (schema test).

## Definition of done

`./pao ci` green; PR merged.
