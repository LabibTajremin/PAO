# Security checklist (P16)

PAO walked against **OWASP ASVS 4.0.3 Level 2** (backend API and admin web) and
**OWASP MASVS-L1** (customer and partner apps). Items are grouped by chapter and by
requirement family; each has a status and where it is enforced or tested.

- **pass** — the control exists and a test or gate shows it.
- **fixed** — found missing in P16, fixed with a test (see "P16 fixes").
- **risk** — accepted risk, with the reason; the owner should confirm (HANDOVER.md).
- **n/a** — the feature does not exist in the MVP.

Gate: `./pao security` (gitleaks on history and on built app bundles, `npm audit`,
osv-scanner over every lockfile, trivy over the source tree and the backend image).
Accepted scanner findings live in `osv-scanner.toml` and `.trivyignore` with reasons.

## P16 fixes

| Finding | Fix | Test |
|---|---|---|
| Backend image shipped npm, npx, corepack and yarn; their bundled packages had 11 high CVEs (trivy) | Final stage deletes them; the runtime never installs packages | `./pao security` with `PAO_SCAN_IMAGE` (CI builds and scans the image) |
| Account deletion left the customer's name, phone, exact address and note in booking snapshots, and names/comments in reviews | `booking` and `rating` erase on `AccountDeleted`; the booking pin is coarsened to ~1 km | `backend/src/app/erasure.int-spec.ts` |
| Deleted accounts kept their avatar and complaint photos | `media` deletes an account's own files on `AccountDeleted`; documents wait for retention | `erasure.int-spec.ts`, `media.spec.ts` |
| No document-retention purge (ADR-0023 decided one year, no job did it) | `verification.purge_closed` (daily 03:45) deletes documents, NID records, items and Level 2 sessions of accounts closed longer than `documents.retention_days` | `erasure.int-spec.ts` (364 days kept, 366 purged) |
| No certificate pinning | `pao_core` pins SPKI SHA-256 hashes from `PAO_PIN_SHA256` on release builds | `pao_core/test/pinning_test.dart` |
| Partner app showed NID/selfie/police previews without FLAG_SECURE (02-architecture §7) | `SecureArea` (moved to `pao_core`) wraps document previews; partner `MainActivity` handles the channel | `pao_core/test/device/secure_screen_test.dart` |
| Only Dart lockfiles were checked against OSV; trivy only ran when asked | `./pao security` scans Dart + npm lockfiles and the source tree always, the image in CI | CI `backend.yml` |

## ASVS 4.0.3 Level 2

### V1 Architecture, design and threat modelling

| Item | Status | Where |
|---|---|---|
| 1.1 Secure SDLC, threat model, all components identified | pass | PRD §9, `docs/architecture.md`, module READMEs, ADRs |
| 1.2 Authentication architecture: one mechanism, least privilege between components | pass | `platform/auth` (EdDSA JWT), modules talk only through contracts (dependency-cruiser in `./pao lint`) |
| 1.4 Access control architecture: enforced server-side at one place, deny by default | pass | `AuthorizationGuard`; `contract.int-spec.ts` (every route has the spec's `x-permission`) |
| 1.5 Input/output architecture: schema validation at the edge | pass | `RequestValidationInterceptor` (Ajv), responses validated in every integration spec |
| 1.6 Cryptographic key management: keys from env, rotation | pass | `JWT_SIGNING_KEY` / `JWT_PREVIOUS_PUBLIC_KEYS`, `DATA_ENCRYPTION_KEY`; runbook (P16 task 3) |
| 1.7 Logging architecture: central, no sensitive data | pass | pino logger with request id; phones/codes never logged (`logging` README) |
| 1.8 Data protection: sensitive data identified and classified | pass | PRD §6.6; NID/documents classed `sensitive` in `media/domain/media.ts` |
| 1.9 Communications: TLS between all components | risk | TLS ends at the load balancer; inside the private network traffic to Postgres/Redis/S3 is plain. Use managed TLS endpoints at deploy |
| 1.14 Configuration: build/deploy segregated, secrets not in repo | pass | `.env.example`, gitleaks in `./pao security` |

### V2 Authentication

| Item | Status | Where |
|---|---|---|
| 2.1 Password security (admin only) | pass | argon2id (`platform/auth/password-hash.ts`); min length in spec; no composition rules |
| 2.2 General authenticator: anti-automation, lockout | pass | OTP per phone, per IP and resend windows (`redis-stores.int-spec.ts`, `auth.int-spec.ts`); admin lockout (`admin.int-spec.ts`) |
| 2.2.3 Notify on credential change | risk | No email/SMS on admin password reset; admins are few and audited (`audit.entries`) |
| 2.5 Credential recovery | pass | Admin reset by a super admin only, audited |
| 2.7 Out-of-band verifier (SMS OTP) | pass | 6 digits, 5 minutes, single use, locks after 4 wrong (`auth.int-spec.ts`) |
| 2.8 Time-based OTP (admin 2FA) | pass | `platform/auth/totp.ts`, required for every admin sign-in |
| 2.9 Cryptographic verifier | n/a | No client certificates or hardware keys |

### V3 Session management

| Item | Status | Where |
|---|---|---|
| 3.1 No tokens in URLs | pass | Bearer header; refresh token body or cookie |
| 3.2 Session binding: new token at sign-in, unpredictable | pass | `random.ts` (crypto RNG), UUIDv7 ids only for records |
| 3.3 Logout and timeout | pass | 15-minute access tokens, denylist on logout (`auth.int-spec.ts`), 30-day refresh |
| 3.4 Cookie attributes | pass | `pao_refresh` is `HttpOnly; Secure; SameSite=Strict; Path=/v1/auth` (`identity/adapter/http/views.ts`) |
| 3.5 Token-based sessions: rotating refresh, reuse detection | pass | `Sessions` ends the family on reuse (ADR-0005, `auth.int-spec.ts`) |
| 3.7 Re-authentication before sensitive actions | pass | Account deletion needs a fresh OTP (`auth.int-spec.ts`) |

### V4 Access control

| Item | Status | Where |
|---|---|---|
| 4.1 Enforced at a trusted service layer, deny by default | pass | Global guards; a route without a decorator is 403 (`api.int-spec.ts`) |
| 4.2.1 Object-level (IDOR) on every owned id | pass | `backend/src/app/idor.int-spec.ts`: every `/v1/customer` and `/v1/provider` route with a path id, derived from `api/openapi.yaml`, called by another account of the same role → 403/404 (reviews answer one uniform 409 for any booking the caller may not review) |
| 4.2.2 CSRF | pass | API is bearer-only; the one cookie is `SameSite=Strict` on `/v1/auth` |
| 4.3 Admin interfaces: MFA, least privilege | pass | TOTP; role matrix (`02-architecture.md` §6), role edits audited |
| Admin `:id` routes | pass | Admins act across accounts by design; each is gated by its permission (`contract.int-spec.ts`), document views audited |

### V5 Validation, sanitisation and encoding

| Item | Status | Where |
|---|---|---|
| 5.1 Input validation against a schema, allow-lists | pass | Ajv on path, query, headers and body → 422 (`api.int-spec.ts`) |
| 5.2 Sanitisation, no template injection | pass | JSON only; no HTML rendering server-side |
| 5.3 Output encoding, SQL injection | pass | sqlc-generated parameterised queries only (`02-architecture.md` §7) |
| 5.5 Deserialisation | pass | `JSON.parse` of a size-limited body (1 MB) |

### V6 Stored cryptography

| Item | Status | Where |
|---|---|---|
| 6.1 Data classification; PII encrypted at rest where required | pass | NID numbers AES-256-GCM (`platform/auth/data-cipher.ts`), lookup by keyed hash |
| 6.2 Approved algorithms | pass | Ed25519, AES-256-GCM, argon2id, SHA-256 |
| 6.3 Random values | pass | `node:crypto` only (`random.ts`) |
| 6.4 Secret management | risk | Keys in env vars, no KMS/vault in the MVP; rotation runbook covers JWT keys |
| Document files at rest | risk | Private bucket, signed 5-minute URLs; server-side encryption is the storage provider's setting (enable SSE at deploy) |

### V7 Error handling and logging

| Item | Status | Where |
|---|---|---|
| 7.1 No sensitive data in logs | pass | Codes and tokens never logged; phones only as account ids |
| 7.2 Security events logged | pass | `audit.entries` for status, money, role and document-view events |
| 7.3 Log protection | pass | `audit.entries` append-only (DB trigger, `audit.int-spec.ts`) |
| 7.4 Generic errors | pass | `ErrorFilter` answers 500 `INTERNAL` without detail |

### V8 Data protection

| Item | Status | Where |
|---|---|---|
| 8.1 Server-side caching of sensitive data | pass | `Cache-Control: no-store` on API answers (edge middleware) |
| 8.2 Client-side: no sensitive data in browser storage | pass | Admin web keeps the refresh token only in the HttpOnly cookie |
| 8.3 Sensitive private data: minimised, deletable, retained only as needed | fixed | Account deletion erases PII in identity, customer, provider, notification, media, booking snapshots and rating (`erasure.int-spec.ts`); documents purged after `documents.retention_days` |
| 8.3 Documents never on customer APIs | pass | `backend/src/app/privacy-contract.spec.ts` walks every customer schema |
| 8.3 Exact address only after acceptance | pass | `booking/adapter/http/flow.int-spec.ts` |
| 8.3 Provider location only while online | pass | `backend/src/app/location-privacy.int-spec.ts` (GEO sets emptied on offline); lost heartbeats reaped (`presence.int-spec.ts`) |
| 8.3 Every document view audited | pass | `media.int-spec.ts`, `media.spec.ts` |
| Audit entries of deleted accounts | risk | Append-only by design; entries hold ids and actions, not names or phones |
| Complaints written by deleted accounts | risk | Kept for dispute handling; the free text may name people; review with counsel (owner) |

### V9 Communications

| Item | Status | Where |
|---|---|---|
| 9.1 TLS for all client connections, HSTS | pass | HTTPS at the load balancer; HSTS header (`api.int-spec.ts`) |
| 9.1 Certificate pinning (mobile) | fixed | see MASVS-NETWORK below |
| 9.2 Server communications encrypted | risk | see 1.9 |

### V10 Malicious code

| Item | Status | Where |
|---|---|---|
| 10.3 Dependencies from trusted sources, pinned | pass | Lockfiles; CI actions pinned by SHA |
| 10.3 Known-vulnerable components | pass | `npm audit`, osv-scanner, trivy in `./pao security` |

### V11 Business logic

| Item | Status | Where |
|---|---|---|
| 11.1 Sequential steps, limits, anti-automation | pass | Booking state machine (`domain.spec.ts` every from/to pair), start-code lockout, idempotency keys |
| Rate limits per route class | pass | API per user (`api.int-spec.ts` "per user"), per IP (`api.int-spec.ts`), OTP per phone/IP (`auth.int-spec.ts`, `redis-stores.int-spec.ts`), admin login per account (`admin.int-spec.ts`), enrolment code resend (`enrolment.int-spec.ts`) |

### V12 Files and resources

| Item | Status | Where |
|---|---|---|
| 12.1 Upload size and type limits | pass | `media/domain/media.ts` rules; checked again on confirm (`media.int-spec.ts`) |
| 12.3–12.5 No path traversal, files outside web root | pass | Server-chosen object keys; private bucket |
| 12.6 SSRF | pass | The API fetches no client-supplied URL |

### V13 API and web service

| Item | Status | Where |
|---|---|---|
| 13.1 Same encoding everywhere, admin CORS allow-list | pass | `api.int-spec.ts` (foreign origin refused) |
| 13.2 RESTful: methods enforced, schema-validated, CSRF | pass | 405 on wrong methods, Ajv |

### V14 Configuration

| Item | Status | Where |
|---|---|---|
| 14.1 Reproducible builds, secured pipeline | pass | `Dockerfile` multi-stage; CI on pinned actions |
| 14.2 Dependencies current and scanned | pass | `./pao security` |
| 14.3 No debug in production | pass | `/__test` hooks only when `APP_ENV=test` |
| 14.4 Security headers | pass | `nosniff`, `X-Frame-Options: DENY`, CSP `default-src 'none'`, HSTS (`api.int-spec.ts`) |
| 14.5 Origin and request validation | pass | `SpecMatchMiddleware`; `X-Forwarded-For` trusted only from private networks |
| Image runs as non-root, no package managers | fixed | `USER node`; npm/yarn removed |

## MASVS-L1 (customer and partner apps)

| Item | Status | Where |
|---|---|---|
| MASVS-STORAGE-1 Sensitive data in secure storage | pass | Tokens in `flutter_secure_storage` (`SecureSessionStore`) |
| MASVS-STORAGE-2 No leaks via logs, backups, screenshots | fixed | FLAG_SECURE on the start code (customer) and document previews (partner) via `SecureArea`; iOS has no flag (risk) |
| MASVS-CRYPTO-1/2 | pass | No client-side crypto beyond TLS and the pin hash |
| MASVS-AUTH-1/2 | pass | Server-side auth; the app only holds tokens |
| MASVS-NETWORK-1 TLS only | pass | Release builds use `https://` `PAO_API_BASE_URL` |
| MASVS-NETWORK-2 Certificate pinning | fixed | `pao_core/lib/src/http/pinning.dart`, see "Certificate pins" |
| MASVS-PLATFORM-1 IPC | pass | One method channel (`pao/secure_screen`), no exported components beyond the launcher |
| MASVS-PLATFORM-3 Screenshots of sensitive screens | fixed | see STORAGE-2 |
| MASVS-CODE-1/2 Up-to-date platform and dependencies | pass | osv-scanner over `pubspec.lock` |
| MASVS-CODE-4 Input validation | pass | Server validates everything; deep links routed through the screen guard |
| MASVS-RESILIENCE | n/a | Not part of L1 |
| No secrets in the app binary | pass | `./pao security` feeds `strings` of every built bundle (`apps/*/build/{web,app/outputs,linux/*/release/bundle}`) to gitleaks. P16 ran it on the release admin web build and the release customer Linux build; APK/AAB bundles are scanned in CI where Android builds run |

## Certificate pins

Release builds pin the **SubjectPublicKeyInfo SHA-256** of the API's TLS key:

```sh
openssl s_client -connect api.pao.example:443 -servername api.pao.example </dev/null 2>/dev/null |
  openssl x509 -pubkey -noout | openssl pkey -pubin -outform der |
  openssl dgst -sha256 -binary | base64
flutter build appbundle --release --dart-define=PAO_PIN_SHA256=<live>,<backup>
```

- Always ship **two** hashes: the live key and a backup key generated in advance and kept
  offline (it is a public-key hash, not a secret, but the private key behind it is).
- Renewing a certificate with the **same key** needs no app release.
- To rotate the key: release apps with `<live>,<backup>`; wait until old versions are
  forced out (minimum-version check); switch the server to the backup key; next release
  ships `<backup>,<new backup>`.
- Debug builds, tests and the admin web app never pin (browsers own TLS).
- If a pin mismatch locks users out, the only recovery is an app release: never pin an
  intermediate you do not control, and never ship a single hash.
