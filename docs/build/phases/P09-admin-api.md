# P09 — Admin API

**Goal:** every admin capability in PRD §7.3 (MVP rows) is available through `/v1/admin/*`
with least-privilege permissions.

**Read first:** PRD §3 (admin roles), §7.3, §8.3; `05-screens.md` admin table.

## Tasks

1. **Dashboard (A-09)** — providers by status and level, bookings per day (last 30),
   completion rate, open complaints, pending verifications. Computed by a read model that
   subscribes to events (no cross-schema joins); cached 60 s in Redis.
2. **Provider and customer management (A-05)** — search, detail, history; suspend, ban,
   reinstate with reason. Ban adds the NID, phone and face reference to the block list
   (PRD §6.4), revokes sessions and forces offline.
3. **Bookings monitor (A-06)** — list with filters (status, service, date, area), detail
   with the full state timeline.
4. **Complaints queue (A-07)** — assign, comment, resolve (built on P08).
5. **Admin users and roles (A-01, A-10)** — invite admin (email + temporary password +
   forced TOTP enrolment), assign roles, deactivate; role-permission editor for super
   admin.
6. **Settings and audit viewer (A-08, A-10)** — wire P04 endpoints into the admin route
   group with the correct permissions.

## Tests

- Integration: each endpoint success + 403 for every role without the permission
  (table generated from `x-permission`), ban flow revokes tokens and removes presence,
  dashboard numbers match seeded fixtures.

## Definition of done

The backend is feature-complete for the MVP. `./pao ci` green; PR merged.
