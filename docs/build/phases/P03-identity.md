# P03 — Identity & access

**Goal:** everyone can sign in securely, and every request is authorised by role,
permission and (for screens) screen ID.

**Read first:** PRD §3 (roles), §6.5, §11 (security), features C-01, P-01, A-01;
`02-architecture.md` §4–§6.

## Tasks

1. **Domain** — `Account` (phone, status Pending/Active/Suspended/Banned, roles), phone
   number value object (Bangladesh `+8801XXXXXXXXX` normalisation), errors.
   One identity may hold both customer and provider roles (PRD §3).
2. **OTP** — request: rate-limit (3/phone/15 min, 10/IP/hour), generate 6 digits, store
   argon2 hash in Redis (5 min, 5 attempts), send through `SmsSender` port (console
   adapter in dev). Verify: constant-time compare, attempts counter, lockout, then
   create-or-load account and issue tokens. Banned identities cannot sign in (PRD §6.4).
3. **Tokens** — access/refresh issue, rotation with family + reuse detection, logout
   (current device), logout everywhere, Redis denylist for live access tokens.
4. **Admin auth** — email + password, then TOTP challenge (`mfa:{challengeID}`),
   lockout after 5 failures, TOTP enrolment on first login, admin refresh cookie.
5. **RBAC** — `GET /v1/me/permissions` returning roles, permissions and screen IDs;
   role management use cases for super admin (bumps `rbac:version`). Provider gate:
   screens limited to M01–M14 while `verification.GetLevel < 1` (calls the verification
   contract through an interface; until P06 use a stub that returns Level 0 in tests only).
6. **Account deletion** — `DELETE /v1/me` with OTP re-confirmation: revoke sessions,
   anonymise PII, publish `AccountDeleted` (other modules erase their data in their
   phases).
7. **HTTP** — implement every `/v1/auth/*` and `/v1/me*` operation from the spec.

## Tests

- Unit: phone normalisation table, OTP attempt/lockout logic, token rotation and reuse
  detection, permission resolution, provider gate.
- Integration: each endpoint success + every documented error; refresh reuse revokes the
  family; banned account gets 403; rate limits return 429 with `Retry-After`;
  every route in the spec rejects a token lacking its `x-permission` (generated test
  table from the spec).

## Definition of done

A user can sign in by OTP, refresh, call a protected route, be denied on a forbidden one
and log out; an admin signs in with 2FA. `./pao ci` green; PR merged.
