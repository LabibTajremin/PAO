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

## 12. Android builds without the upload key

- **Decision:** when `PAO_ANDROID_KEYSTORE_BASE64` is not set, the Android jobs build a
  debug-signed APK and log a warning, on `main` as well. Before, a push to `main` failed.
- **Why:** the MVP shares APKs directly and has no Play listing yet, so a red `main`
  only blocked work without protecting anything.
- **How to change it:** add the four `PAO_ANDROID_*` secrets (deployment §4.4, §4.8);
  builds are then upload-key signed. To make a missing key fail `main` again, restore
  the `refs/heads/main` check in `.github/workflows/frontend.yml` ("Install the upload key").

## 13. SMS verification switch

**Decision.** `SMS_VERIFICATION_ENABLED` (`Sms:VerificationEnabled`, default `true`) lets
the MVP launch without an SMS provider. When `false`, a code request runs every check it
runs today (phone format, ban list, per-phone and per-IP throttle) and stores a code,
but the code is `SMS_FIXED_CODE` (`Sms:FixedCode`, default `123456`, exactly 6 digits)
and the SMS adapter is not called. Verify is unchanged: attempts, lockout, expiry, the
purpose binding, account bans, token issuance and audit behave exactly as with SMS on.
`ConfigValidator` then accepts `APP_ENV=prod` with the console adapter and no
sslwireless credentials (push must still be real: `production needs a real
PUSH_ADAPTER`), and every host logs `SMS verification is OFF` at start and
`sms_verification: off` in its ready line.

**Why.** The owner deploys for free first and has no SMS contract. Storing the fixed code
instead of skipping the store keeps every abuse control in one code path, so turning
SMS on later changes only where the code comes from. The apps need no change: they never
read the SMS, the user types the code.

**Risk.** Anyone who knows the code can sign in as any phone. Acceptable for a closed
beta; not for a public launch.

**Change it by** setting `SMS_ADAPTER=sslwireless`, the two `SSLWIRELESS_*` secrets and
`SMS_VERIFICATION_ENABLED=true` and redeploying (`docs/guides/deployment.md` §3.2.1).

## 14. Background jobs in the API

**Decision.** `JOBS_IN_API` (`Jobs:RunInApi`, default `false`) lets the API process run
everything the worker runs: the outbox relay that delivers events to their subscribers
(notifications and push, commission on `BookingCompleted`, opening the rating, dashboard
and read-model stats, audit) and the scheduler with every job (booking expiry every 15 s,
merchant presence reap, media orphan purge, document expiry and reminders, closed-account
purge, outbox purge). The API calls `AddBackgroundJobsInApi`
(`PAO.Core/Registration/BackgroundJobsInApiRegistration.cs`), which calls the worker's own
`AddBackgroundJobs` when the setting is on and adds nothing when it is off, so there is
one list of background services and the job classes are untouched. The hosted
`WorkerLoop` starts after the API's start-up checks and stops with the API; `/readyz` does
not depend on it. The API logs `background jobs: in api` or `background jobs: in worker`
at start; the worker logs `background jobs: in worker` and warns if it sees
`JOBS_IN_API=true`. The MVP on Render's free plan sets it to `true` and runs no worker
(`docs/guides/deployment.md` §3.4.1). The worker host is unchanged.

**Why.** The free plan runs one web service and no background worker, and without the
worker bookings never time out and no event is delivered. Reusing the worker's
registration keeps both hosts identical and costs no new code paths. Running both is not
a correctness problem: job runs take a Postgres advisory lock per job, the relay claims
outbox rows with `FOR UPDATE SKIP LOCKED` and marks them published in the same
transaction, and handlers are idempotent; the same rules already let several workers
overlap during a release. It only doubles the polling and loosens per-aggregate order to
"within one relay", so the guides say to run one of them.

**Trade-offs.** On the free plan the API sleeps after about 15 minutes without requests
and the jobs sleep with it: events wait in the outbox and the expiry sweep catches up on
waking, but a daily run that falls in a sleep is skipped (purges and document expiry
catch up the next day; that day's expiry reminders are not sent). Job and outbox metrics
are served on the API's metrics port. The architecture rule that kept `PAO.Core` away
from `PAO.BackgroundJobs` now allows that one registration class only
(`Only_the_jobs_in_api_registration_uses_the_background_jobs`).

**How to revert.** Start the worker service (`/app/worker`, same image and environment),
wait for its health check, then set `JOBS_IN_API=false` (or remove it) on the API and
redeploy it. To remove the option entirely: delete
`BackgroundJobsInApiRegistration.cs` and its call in `PAO.Core/Program.cs`, the
`PAO.BackgroundJobs` reference in `PAO.Core.csproj`, `JobsOptions.RunInApi`, the
`JOBS_IN_API` mapping and `RunInApi` in `Config/jobs.json`, and restore `PAO.BackgroundJobs`
to the forbidden list of `PAO.Core` in `ArchitectureTests`.
