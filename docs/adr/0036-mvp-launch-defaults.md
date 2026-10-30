# ADR-0036: MVP launch defaults

- Status: Accepted
- Date: 2026-10-30
- Source: owner instruction "do every remaining pre-launch item that can be done in code;
  where it needs a business decision, choose the simplest MVP default and document it so
  it can be changed later". Closes the code items of the former "Gaps to close before
  launch" in `docs/guides/deployment.md`.

Each section is one decision: what was chosen, why, and how to change it. Placeholder
values are collected in [`docs/guides/launch-values.md`](../guides/launch-values.md).

## 1. First production admin

**Decision.** `/app/migrate create-admin --email E --name N` creates one `super_admin` in
any environment, production included. The password comes from `ADMIN_PASSWORD` (never
argv), at least 12 characters, hashed with argon2id like every admin password. An
existing email is left untouched and the command exits 0 (`already exists; nothing
changed`), so a release script may repeat it. The admin is not asked to change the
password (the operator chose it) but, like every admin, must enrol TOTP at the first
sign-in before the console opens.

**Why.** `migrate seed` deliberately creates no admins in production, and inviting needs
an admin. A one-off command in the same image needs no new endpoint or bootstrap secret
on the API.

**How to change.** Invite further admins from the console (A-10). To force a password
change too, set `MustChangePassword` in `AdminUsers.Ensure` for this path.

## 2. Admin CORS origins

**Decision.** `ADMIN_CORS_ORIGIN` takes one origin or a comma-separated list; each must be
an exact `http(s)://host[:port]` origin without path, query, user info or trailing slash,
checked at start-up. No wildcards. Production lists only the production admin origin;
Vercel previews call staging, which lists the staging alias and any fixed preview alias.

**Why.** Exact matching keeps credentials-bearing CORS safe; a list is the smallest change
that lets a preview or a second admin host work. A single value works as before.

**How to change.** Edit the variable and restart the API.

## 3. FCM credentials without secret files

**Decision.** `FCM_CREDENTIALS_JSON` holds the service-account JSON, raw or base64, as an
alternative to `FCM_CREDENTIALS_FILE`. With `PUSH_ADAPTER=fcm` one of them is required;
the file wins when both are set.

**Why.** Fly.io and Railway offer only variables; base64 avoids multi-line values.

**How to change.** Switch between the two variables at any time; restart API and worker.

## 4. Bucket encryption and creation

**Decision.** `S3_ENSURE_ENCRYPTION` (`Storage:EnsureEncryption`, default `true`) controls
the `PutBucketEncryption` call at start-up; set it to `false` on Cloudflare R2, which
encrypts every object at rest itself. Creating a bucket that the same account created a
moment earlier (`BucketAlreadyOwnedByYou`, API and worker starting together) counts as
success; a name owned by another account (`BucketAlreadyExists`) still fails start-up.

**Why.** PRD §6.6 needs encryption at rest, which R2 provides by default; failing start-up
on an unsupported call would block the recommended storage.

**How to change.** Set the variable; on AWS S3 leave it `true`.

## 5. Billing setting bounds

**Decision.** The settings API rejects `billing.commission_rate_bp` above 10000 (100%)
and, as for every integer setting, any negative value (so `billing.due_block_amount < 0`)
with `422 SETTING_INVALID`, the existing code.

**Why.** Basis points above 10000 would charge more than the job price; the old code
silently clamped on read, hiding the mistake.

**How to change.** Bounds live in `AdminRules.Maximums`.

## 6. Details on `MERCHANT_DUE_LIMIT`

**Decision.** The 409 from accepting carries `details.duePaisa` and
`details.blockAmountPaisa` (the envelope's existing free-form `details`); the spec says
so on `acceptRequest`. The partner app names both amounts when present and falls back to
the generic message otherwise.

**Why.** The merchant needs to know how much to pay; the change is additive.

**How to change.** `BookingPeers.EnsureCanAccept` builds the details.

## 7. App builds in CI

**Decision.** `tools/build-release.sh` forwards `PAO_PIN_SHA256` and `PAO_SENTRY_DSN` when
set; an empty or missing value leaves pinning or Sentry off, as before. The FCM App ID is
`PAO_FCM_APP_ID_<APP>_<ANDROID|IOS>` when set, else `PAO_FCM_APP_ID` (CI: the old per-app
secret). CI passes these secrets to both Android and iOS builds. The dev and staging
flavours share the prod App ID and get no push in the MVP.

**Why.** Firebase issues one App ID per platform and application ID; pins and the DSN
must not live in the repository.

**How to change.** Add the secrets; for push on dev/staging, register those apps in
Firebase and pass their App IDs per build.

## 8. Data key rotation

**Decision.** `DATA_ENCRYPTION_PREVIOUS_KEYS` lists earlier keys (newest first, original
last). Data decrypts under any listed key and is encrypted with the current one;
`/app/migrate reencrypt` rewrites both encrypted columns to the current key in one
transaction and is idempotent. Lookup hashes stay on the original key, which therefore
stays in the list for the life of the database. Runbook:
[`rotate-data-key.md`](../runbooks/rotate-data-key.md).

**Why.** Blocked NIDs are kept only as hashes; re-keying them is impossible, and making
the hash key independent of rotation keeps the block list working.

**How to change.** A separate lookup key would need a migration that re-hashes
`nid_records` from plaintext and accepts losing `blocked_nids` entries without a
matching record.

## 9. Cross-account sweep

**Decision.** `CrossAccountTests` reads the bundled contract, finds every customer and
provider route with an owned path id, fails if any lacks a case, and calls each as a
second account of the same role, expecting 403/404 (reviews: the uniform
`409 REVIEW_NOT_ALLOWED`). ASVS 4.2.1 is closed.

**How to change.** A new owned-id route fails the test until a case is added.

## 10. Idempotent replay race

**Decision.** The idempotency filter buffers the answer and stores it in Redis before
the first byte reaches the client. It used to store it in `Response.OnCompleted`, which
runs after the client has the response: a client retrying at once found the key still
"running" and got `409 IDEMPOTENCY_IN_PROGRESS` instead of the replay. That was the
flaky `Idempotent_operations_replay_the_first_answer` (409 instead of 410). Answers of
idempotent operations are small JSON bodies, so buffering costs nothing noticeable.

## 11. Business defaults

| Item | MVP default | Change it by |
|---|---|---|
| Hostnames | `api.pao.com.bd`, `api.staging.pao.com.bd`, `admin.pao.com.bd`, `admin-staging.pao.com.bd` (placeholders) | `launch-values.md` lists every file |
| Support contact | `09610000000`, `support@pao.com.bd` (placeholders) | `config/<flavour>.json` per app |
| App icons | Flutter defaults until the owner supplies artwork | replace the icon sets (`launch-values.md`) |
| Load-test warm-up | 5 s at the test rate, reported but not judged | `NearbySearch.WarmUp` |
| Deploys | manual per `docs/runbooks/deploy.md`, by image digest; the `backend-image` workflow (manual trigger) builds and pushes the image to GHCR and does not deploy | add a deploy step once a host is chosen |
| Signing and store upload | owner action: secrets and steps in `deployment.md` "Gaps"; upload by hand | add a store-upload job later (fastlane or the store APIs) |
