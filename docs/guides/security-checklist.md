# Security checklist (P16)

PAO walked against **OWASP ASVS 4.0.3 Level 2** (backend API and admin web) and
**OWASP MASVS-L1** (customer and partner apps). Items are grouped by chapter and by
requirement family; each has a status and where it is enforced or tested.

- **pass** — the control exists and a test or gate shows it.
- **fixed** — found missing in P16, fixed with a test (see "P16 fixes").
- **risk** — accepted risk, with the reason; the owner should confirm (docs/HANDOVER.md).
- **n/a** — the feature does not exist in the MVP.

Gate: `./pao security` (gitleaks on history and on built app bundles, osv-scanner over
every lockfile — Dart `pubspec.lock` and the NuGet `packages.lock.json` files — and trivy
over the source tree and the backend image). Scanner configuration and accepted findings
live in `infra/security/` (`gitleaks.toml`, `osv-scanner.toml`, `trivyignore`) with reasons.

The audit was done in P16 and re-checked against the .NET backend after P17. Evidence
names the C# test as `Class.Method`: unit tests live in `Backend/Test/PAO.UnitTests`,
integration tests in `Backend/Test/PAO.IntegrationTests`, journeys in
`Backend/Test/PAO.E2ETests`. Rows marked *gap* name a check the earlier suite had and
the C# suite does not yet repeat; the control itself is in place.

## P16 fixes

| Finding | Fix | Test |
|---|---|---|
| Backend image shipped npm, npx, corepack and yarn; their bundled packages had 11 high CVEs (trivy) | The image is now the ASP.NET runtime with no package manager; the runtime never installs packages | `./pao security` with `PAO_SCAN_IMAGE` (CI builds and scans the image) |
| Account deletion left the customer's name, phone, exact address and note in booking snapshots, and names/comments in reviews | `booking` and `rating` erase on `AccountDeleted`; the booking pin is coarsened to ~1 km | `BookingSupportTests.Monitors_bookings_for_support`, `RatingApiTests.Opens_once_pages_reviews_erases_authors_and_fails_without_the_database` |
| Deleted accounts kept their avatar and complaint photos | `media` deletes an account's own files on `AccountDeleted`; documents wait for retention | `MediaApiTests.Deleted_accounts_lose_their_files_documents_only_with_the_retention_purge` |
| No document-retention purge (ADR-0023 decided one year, no job did it) | `verification.purge_closed` (daily 03:45) deletes documents, NID records, items and Level 2 sessions of accounts closed longer than `documents.retention_days` | `VerificationLifecycleTests.Closed_accounts_keep_documents_for_the_retention_period_then_lose_them` (364 days kept, 366 purged) |
| No certificate pinning | `pao_core` pins SPKI SHA-256 hashes from `PAO_PIN_SHA256` on release builds | `pao_core/test/pinning_test.dart` |
| Partner app showed NID/selfie/police previews without FLAG_SECURE (02-architecture §7) | `SecureArea` (moved to `pao_core`) wraps document previews; partner `MainActivity` handles the channel | `pao_core/test/device/secure_screen_test.dart` |
| Only Dart lockfiles were checked against OSV; trivy only ran when asked | `./pao security` scans the Dart and NuGet lockfiles and the source tree always, the image in CI | CI `backend.yml` (`tooling` job) |

## ASVS 4.0.3 Level 2

### V1 Architecture, design and threat modelling

| Item | Status | Where |
|---|---|---|
| 1.1 Secure SDLC, threat model, all components identified | pass | PRD §9, `docs/guides/architecture.md`, module READMEs, ADRs |
| 1.2 Authentication architecture: one mechanism, least privilege between components | pass | `TokenSigner`/`TokenVerifier` (EdDSA JWT); areas talk only through shared services (`ArchitectureTests.Areas_reach_other_areas_only_through_their_shared_services`) |
| 1.4 Access control architecture: enforced server-side at one place, deny by default | pass | `AccessFilter`; `AuthorizationTests.Every_attribute_matches_the_spec_permission_and_security`, `RbacContractTests.Every_protected_route_refuses_a_token_without_its_permission` |
| 1.5 Input/output architecture: schema validation at the edge | pass | `RequestValidationFilter` (`SchemaValidator`, Ajv wording); `ApiTests.Bodies_are_validated_against_the_spec_before_the_action`, `OpenApiTests.Validates_parameters_after_coercing_them` |
| 1.6 Cryptographic key management: keys from env, rotation | pass | `JWT_SIGNING_KEY` / `JWT_PREVIOUS_PUBLIC_KEYS`, `DATA_ENCRYPTION_KEY` / `DATA_ENCRYPTION_PREVIOUS_KEYS` + `migrate reencrypt`; runbooks `rotate-jwt-keys.md`, `rotate-data-key.md` |
| 1.7 Logging architecture: central, no sensitive data | pass | `PaoJsonFormatter` (Serilog JSON lines with request id; `LoggingTests.Writes_one_json_line_per_event`); phones/codes never logged (`Backend/Docs/Operations`) |
| 1.8 Data protection: sensitive data identified and classified | pass | PRD §6.6; NID/documents classed sensitive in `MediaRules` (`MediaRuleTests.Each_uploader_may_send_only_its_purposes_within_type_and_size`) |
| 1.9 Communications: TLS between all components | risk | TLS ends at the load balancer; inside the private network traffic to Postgres/Redis/S3 is plain. Use managed TLS endpoints at deploy |
| 1.14 Configuration: build/deploy segregated, secrets not in repo | pass | `.env.example`, gitleaks in `./pao security` |

### V2 Authentication

| Item | Status | Where |
|---|---|---|
| 2.1 Password security (admin only) | pass | argon2id (`SecretHasher`; `SecretTests.Hashes_in_phc_format_and_verifies_its_own`); min length in spec; no composition rules |
| 2.2 General authenticator: anti-automation, lockout | pass | OTP per phone, per IP and resend windows (`IdentityStoreTests.The_throttle_skips_the_ip_window_for_server_side_sends`, `AuthApiTests.Validates_phones_throttles_resends_and_locks_out_wrong_codes`); admin lockout (`AdminApiTests.Locks_out_after_five_wrong_passwords_and_expires_unknown_challenges`) |
| 2.2.3 Notify on credential change | risk | No email/SMS on admin password reset; admins are few and audited (`audit.entries`) |
| 2.5 Credential recovery | pass | Admin reset by a super admin only, audited |
| 2.7 Out-of-band verifier (SMS OTP) | pass | 6 digits, 5 minutes, single use, locks on the fifth wrong guess (`AuthApiTests.Validates_phones_throttles_resends_and_locks_out_wrong_codes`, `IdentityRulesTests.Accepts_a_matching_code_then_locks_out_on_the_fifth_wrong_guess`) |
| 2.8 Time-based OTP (admin 2FA) | pass | `Totp` (`SecretTests.Totp_codes_match_otplib_with_one_step_of_drift`), required for every admin sign-in (`AdminTests.Enrols_totp_on_the_first_login_then_logs_in_with_the_stored_secret`) |
| 2.9 Cryptographic verifier | n/a | No client certificates or hardware keys |

### V3 Session management

| Item | Status | Where |
|---|---|---|
| 3.1 No tokens in URLs | pass | Bearer header; refresh token body or cookie |
| 3.2 Session binding: new token at sign-in, unpredictable | pass | `RandomSecrets` (crypto RNG; `SecretTests.Random_secrets_have_the_requested_shape`), UUIDv7 ids only for records |
| 3.3 Logout and timeout | pass | 15-minute access tokens, denylist on logout (`AuthApiTests.Signs_in_by_otp_refreshes_detects_reuse_and_logs_out`), 30-day refresh |
| 3.4 Cookie attributes | pass | `pao_refresh` is `HttpOnly; Secure; SameSite=Strict; Path=/v1/auth` (`AuthController`; `IdentityRulesTests.The_admin_cookie_is_http_only_and_clears_with_a_zero_age`, `AdminApiTests.Refreshes_by_cookie_changes_the_password_and_logs_out_clearing_the_cookie`) |
| 3.5 Token-based sessions: rotating refresh, reuse detection | pass | `Sessions` ends the family on reuse (ADR-0005, `SessionsTests.Rotates_the_refresh_token_and_revokes_the_family_on_reuse`, `AuthApiTests.Signs_in_by_otp_refreshes_detects_reuse_and_logs_out`) |
| 3.7 Re-authentication before sensitive actions | pass | Account deletion needs a fresh OTP (`AuthApiTests.Deletes_the_account_after_a_fresh_code`, `AuthApiTests.Answers_a_role_less_account_and_a_deletion_without_a_code`) |

### V4 Access control

| Item | Status | Where |
|---|---|---|
| 4.1 Enforced at a trusted service layer, deny by default | pass | `AccessFilter` on every action; an action without an access attribute fails the build gate (`AuthorizationTests.The_audit_catches_missing_and_wrong_attributes`); `ApiTests.Protected_operations_need_a_valid_unrevoked_token_and_the_permission` |
| 4.2.1 Object-level (IDOR) on every owned id | pass | Booking routes called by another merchant or a stranger customer → 404 (`BookingSupportTests.Hides_the_booking_serves_the_contract_and_pages_earnings`); each side kept to its own endpoints (`BookingExitTests.Keeps_each_side_to_its_own_endpoints`); app roles refused on the admin API (`RbacJourney.Rbac_app_users_cannot_reach_the_admin_api`); the spec-driven sweep calls every `/v1/customer` and `/v1/provider` route with an owned path id as another account of the same role and fails on any route without a case (`CrossAccountTests`, ADR-0036) |
| 4.2.2 CSRF | pass | API is bearer-only; the one cookie is `SameSite=Strict` on `/v1/auth` |
| 4.3 Admin interfaces: MFA, least privilege | pass | TOTP; role matrix (`02-architecture.md` §6), role edits audited |
| Admin `:id` routes | pass | Admins act across accounts by design; each is gated by its permission (`RbacContractTests.Every_role_reaches_exactly_its_seeded_permissions`), document views audited |

### V5 Validation, sanitisation and encoding

| Item | Status | Where |
|---|---|---|
| 5.1 Input validation against a schema, allow-lists | pass | Spec schemas on path, query, headers and body → 422 (`ApiTests.Bodies_are_validated_against_the_spec_before_the_action`, `OpenApiTests.Validates_bodies_in_ajv_words`) |
| 5.2 Sanitisation, no template injection | pass | JSON only; no HTML rendering server-side |
| 5.3 Output encoding, SQL injection | pass | EF Core and interpolated `ExecuteSqlAsync` only, both parameterised (`02-architecture.md` §7) |
| 5.5 Deserialisation | pass | `System.Text.Json` over a size-limited body (`Http:MaxBodyBytes`, 1 MiB; `EdgeMiddleware.ReadBody`) |

### V6 Stored cryptography

| Item | Status | Where |
|---|---|---|
| 6.1 Data classification; PII encrypted at rest where required | pass | NID numbers AES-256-GCM (`DataCipher`; `SecretTests.Decrypts_existing_ciphertext_and_derives_the_same_lookup_hash`), lookup by keyed hash |
| 6.2 Approved algorithms | pass | Ed25519, AES-256-GCM, argon2id, SHA-256 |
| 6.3 Random values | pass | `RandomNumberGenerator` only (`RandomSecrets`, `SecretHasher`, `DataCipher`) |
| 6.4 Secret management | risk | Keys in env vars, no KMS/vault in the MVP; rotation runbooks cover the JWT and data keys |
| Document files at rest | risk | Private bucket, signed 5-minute URLs; server-side encryption is the storage provider's setting (enable SSE at deploy) |

### V7 Error handling and logging

| Item | Status | Where |
|---|---|---|
| 7.1 No sensitive data in logs | pass | Codes and tokens never logged; phones only as account ids |
| 7.2 Security events logged | pass | `audit.entries` for status, money, role and document-view events |
| 7.3 Log protection | pass | `audit.entries` append-only (DB trigger, `AuditApiTests.Pages_and_filters_stays_append_only_and_reports_a_lost_database`) |
| 7.4 Generic errors | pass | `ErrorResponses` answers 500 `INTERNAL` without detail (`ErrorResponseTests.Hides_unexpected_errors_and_replays_stored_answers`) |

### V8 Data protection

| Item | Status | Where |
|---|---|---|
| 8.1 Server-side caching of sensitive data | pass | `Cache-Control: no-store` on API answers (edge middleware) |
| 8.2 Client-side: no sensitive data in browser storage | pass | Admin web keeps the refresh token only in the HttpOnly cookie |
| 8.3 Sensitive private data: minimised, deletable, retained only as needed | fixed | Account deletion erases PII in identity, customer, provider, notification, media, booking snapshots and rating (`AccountTests.Erases_the_account_ends_its_sessions_and_tells_the_other_areas`, `CustomerApiTests.Needs_a_profile_first_saves_it_and_erases_it_with_the_account`, `NotificationApiTests.Read_state_pages_and_erasure_work_per_recipient_and_app`, `BookingSupportTests.Monitors_bookings_for_support`, `RatingApiTests.Opens_once_pages_reviews_erases_authors_and_fails_without_the_database`); documents purged after `documents.retention_days` (`VerificationLifecycleTests.Closed_accounts_keep_documents_for_the_retention_period_then_lose_them`) |
| 8.3 Documents never on customer APIs | pass | `OpenApiTests.Customer_answers_never_carry_verification_documents` walks every `/v1/customer` response schema |
| 8.3 Exact address only after acceptance | pass | `BookingFlowTests.Runs_a_job_with_extras_to_the_receipt` (no `line1` before acceptance), `BookingRuleTests.Cancels_until_the_job_starts_and_shares_contacts_only_after_acceptance` |
| 8.3 Provider location only while online | pass | `MerchantPresenceTests.Goes_online_beats_goes_offline_and_is_reaped` (unavailable once offline; lost heartbeats reaped) |
| 8.3 Every document view audited | pass | `MediaApiTests.A_provider_document_is_uploaded_confirmed_and_shown_with_an_audit_entry` |
| Audit entries of deleted accounts | risk | Append-only by design; entries hold ids and actions, not names or phones |
| Complaints written by deleted accounts | risk | Kept for dispute handling; the free text may name people; review with counsel (owner) |

### V9 Communications

| Item | Status | Where |
|---|---|---|
| 9.1 TLS for all client connections, HSTS | pass | HTTPS at the load balancer; HSTS header (`EdgeMiddlewareTests.Sets_security_headers_and_cors_for_the_admin_origin_only`) |
| 9.1 Certificate pinning (mobile) | fixed | see MASVS-NETWORK below |
| 9.2 Server communications encrypted | risk | see 1.9 |

### V10 Malicious code

| Item | Status | Where |
|---|---|---|
| 10.3 Dependencies from trusted sources, pinned | pass | Lockfiles; CI actions pinned by SHA |
| 10.3 Known-vulnerable components | pass | osv-scanner, trivy in `./pao security` |

### V11 Business logic

| Item | Status | Where |
|---|---|---|
| 11.1 Sequential steps, limits, anti-automation | pass | Booking state machine (`BookingRuleTests.Allows_exactly_the_transitions_of_the_state_table`, every from/to pair), start-code lockout (`BookingRuleTests.Locks_the_start_code_after_five_wrong_tries`), idempotency keys (`ApiTests.Idempotent_operations_replay_the_first_answer`) |
| Rate limits per route class | pass | API per user (`ApiTests.Signed_in_calls_are_rate_limited_per_user`), per IP (`ApiTests.Anonymous_calls_are_rate_limited_per_ip`), OTP per phone/IP (`AuthApiTests.Validates_phones_throttles_resends_and_locks_out_wrong_codes`, `IdentityStoreTests.The_throttle_skips_the_ip_window_for_server_side_sends`), admin login per account (`AdminApiTests.Locks_out_after_five_wrong_passwords_and_expires_unknown_challenges`), enrolment codes keep the per-phone windows (`IdentityStoreTests.The_throttle_skips_the_ip_window_for_server_side_sends`) |

### V12 Files and resources

| Item | Status | Where |
|---|---|---|
| 12.1 Upload size and type limits | pass | `MediaRules` (`MediaRuleTests.Each_uploader_may_send_only_its_purposes_within_type_and_size`); checked again on confirm (`MediaApiTests.Each_app_keeps_its_upload_rules`) |
| 12.3–12.5 No path traversal, files outside web root | pass | Server-chosen object keys; private bucket |
| 12.6 SSRF | pass | The API fetches no client-supplied URL |

### V13 API and web service

| Item | Status | Where |
|---|---|---|
| 13.1 Same encoding everywhere, admin CORS allow-list | pass | `EdgeMiddlewareTests.Sets_security_headers_and_cors_for_the_admin_origin_only` (foreign origin refused) |
| 13.2 RESTful: methods enforced, schema-validated, CSRF | pass | 405 on wrong methods (`ApiTests.Unknown_routes_and_methods_are_rejected_before_controllers`), spec schemas |

### V14 Configuration

| Item | Status | Where |
|---|---|---|
| 14.1 Reproducible builds, secured pipeline | pass | `Dockerfile` multi-stage; CI on pinned actions |
| 14.2 Dependencies current and scanned | pass | `./pao security` |
| 14.3 No debug in production | pass | `/__test` hooks only when `APP_ENV=test` (`TestHookTests.Without_seams_the_hooks_answer_not_found_or_not_wired`) |
| 14.4 Security headers | pass | `nosniff`, `X-Frame-Options: DENY`, CSP `default-src 'none'`, HSTS (`EdgeMiddlewareTests.Sets_security_headers_and_cors_for_the_admin_origin_only`) |
| 14.5 Origin and request validation | pass | `EdgeMiddleware` spec match (`EdgeMiddlewareTests.Matches_operations_and_answers_404_and_405_before_controllers`); `X-Forwarded-For` trusted only from private networks (`EdgeMiddlewareTests.Trusts_forwarded_for_only_from_private_peers`) |
| Image runs as non-root, no package managers | fixed | `USER app` on the ASP.NET runtime image (`Backend/docker/Dockerfile`); no package manager in the final stage |

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
