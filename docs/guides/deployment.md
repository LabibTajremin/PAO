# Deploying PAO

How to put PAO into production: the admin web on Vercel, the backend on managed
services, and the customer and partner apps on the stores. Every variable, flag and
script named here exists in the repository; where something the deployment needs does
not exist yet, the guide says so (see [Gaps](#gaps-to-close-before-launch)).

Related: [`docs/guides/release.md`](release.md) (flavours, signing, store checklist),
[`docs/runbooks/deploy.md`](../runbooks/deploy.md) (routine backend deploys),
[`docs/runbooks/rollback.md`](../runbooks/rollback.md),
[`docs/runbooks/rotate-jwt-keys.md`](../runbooks/rotate-jwt-keys.md).

## 1. Overview

### What gets deployed

| Piece | Source | Runs as |
|---|---|---|
| Admin web | `Frontend/apps/admin` (Flutter web) | static files (`build/web`) |
| API | `Backend/PAO.Core` → `/app/api` | long-running ASP.NET Core server on `HTTP_ADDR` (`:8080`), metrics on `METRICS_ADDR` (`:9090`) |
| Worker | `Backend/PAO.Worker` → `/app/worker` | long-running process: outbox relay and periodic jobs, liveness on `:9090/healthz` |
| Migrations | `Backend/PAO.Migrator` → `/app/migrate up` / `seed` | one-off job per release |
| PostgreSQL 16 + PostGIS 3 | — | managed database (migrations run `CREATE EXTENSION postgis` and `pg_trgm`) |
| Redis 7 | — | sessions, refresh tokens, OTP codes, rate limits, cache (StackExchange.Redis) |
| S3-compatible storage | — | two buckets (`S3_BUCKET_PRIVATE`, `S3_BUCKET_PUBLIC`); the API creates them at start-up if missing |
| FCM | Firebase | push to the mobile apps (`PUSH_ADAPTER=fcm`) |
| SMS | SSL Wireless | OTP delivery (`SMS_ADAPTER=sslwireless`) |
| Customer and partner apps | `Frontend/apps/customer`, `Frontend/apps/partner` | Play Store and App Store |

One Docker image (`Backend/docker/Dockerfile`, built from `Backend/`) holds all three backend entry points
(`/app/api` is the default `ENTRYPOINT`; `/app/worker` and `/app/migrate` are chosen by
overriding it).

```mermaid
flowchart LR
  subgraph Clients
    A[Admin web<br/>Vercel static]
    C[Customer app]
    P[Partner app]
  end
  A -- HTTPS + CORS --> API
  C -- HTTPS, pinned --> API
  P -- HTTPS, pinned --> API
  C -- Geocoding --> G[maps.googleapis.com]
  subgraph Container host
    API[API /app/api]
    W[Worker /app/worker]
    M[/app/migrate up/]
  end
  API --> PG[(Postgres + PostGIS)]
  API --> R[(Redis)]
  API --> S3[(S3 / R2)]
  W --> PG
  W --> R
  W --> FCM[FCM]
  W --> SMS[SSL Wireless]
  M --> PG
  A -. signed URLs .-> S3
  C -. signed URLs .-> S3
  P -. signed URLs .-> S3
  FCM --> C
  FCM --> P
```

### What Vercel can and cannot host

| Piece | On Vercel? | Why |
|---|---|---|
| Admin web | **Yes, recommended.** | It is a static Flutter web build. Vercel's build image has no Flutter, so build elsewhere and upload the output (§2). |
| API | **No.** | It is an ASP.NET Core (.NET 10) server; Vercel Functions have no .NET runtime, and the host also serves metrics on a second port. |
| Worker | **No.** | It is a long-running scheduler plus an outbox relay that polls Postgres continuously (`PAO.Worker`). Functions are request-scoped with a maximum duration; there is no long-lived process. Vercel Cron could only trigger jobs if each job were exposed as an HTTP endpoint, and none is. |
| Migrations | No | One-off job; run from CI or the container host. |
| Postgres / Redis / S3 | Through marketplace integrations (Neon, Upstash) | They are external services either way. |

Run the API and worker on a container host; the image is the one CI builds and tests.

### Recommended setup

| Piece | Recommended | Alternative |
|---|---|---|
| Admin web | Vercel (prebuilt static deploy) | any static host / CDN |
| API | Container host: **Render**, **Fly.io**: create two apps from `Backend/` (e.g. `pao-api` and `pao-worker`). In the
API's `fly.toml` set `[deploy] release_command = "/app/migrate up"` and
`[http_service] internal_port = 8080` with an HTTP check on `/readyz`. In the worker's
`fly.toml` set `[experimental] entrypoint = ["/app/worker"]` and no `http_service`.
Set §3.2 on both with `fly secrets set KEY=value …`.

**Railway**, using `Backend/docker/Dockerfile` | any container platform (ECS, Cloud Run, Kubernetes) |
| Worker | Same container host, same image, entry point `/app/worker` | — (cannot run on Vercel) |
| Migrations | Same image, `/app/migrate up`, as a release/pre-deploy command | GitHub Actions job |
| Postgres | **Neon** (PostGIS is supported) | Vercel Postgres (Neon-backed), AWS RDS |
| Redis | **Upstash** (`rediss://` URL) | Redis Cloud, the container host's Redis |
| Storage | **Cloudflare R2** | AWS S3 |

Trade-offs: a container host keeps the backend exactly as tested in CI (same image, same
health checks, metrics port available) at the cost of a second platform; Vercel
Functions cannot run the .NET API at all. Pick a region near
Bangladesh (Singapore or Mumbai) for the database, Redis and the API together.

## 2. Admin web on Vercel

### 2.1 Build

The admin app reads only `PAO_FLAVOUR` and `PAO_API_BASE_URL`, from
`Frontend/apps/admin/config/<flavour>.json`. Edit those files to the real API host
before building (prod points at `https://api.pao.com.bd`, a placeholder until
confirmed). Flutter 3.47.7 is the version CI uses.

```sh
# from the repository root
tools/build-release.sh admin prod          # → Frontend/apps/admin/build/web
tools/build-release.sh admin staging       # staging API
# served under a path instead of the domain root:
PAO_WEB_BASE_HREF=/admin/ tools/build-release.sh admin prod
```

The script runs `flutter build web --release --dart-define-from-file=config/<flavour>.json
--csp --no-web-resources-cdn --no-source-maps --base-href=/`.

### 2.2 `vercel.json`

Place this file in `Frontend/apps/admin/build/web/` after each build (the build
directory is git-ignored, so keep a copy in your deploy script or CI step). Replace
`api.pao.com.bd` and `<storage host>` with your API host and `S3_PUBLIC_ENDPOINT` host.

```json
{
  "cleanUrls": false,
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "Content-Security-Policy", "value": "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https://<storage host>; font-src 'self'; connect-src 'self' https://api.pao.com.bd https://<storage host>; frame-ancestors 'none'; base-uri 'self'; form-action 'self'" },
        { "key": "Strict-Transport-Security", "value": "max-age=31536000; includeSubDomains" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "no-referrer" }
      ]
    },
    {
      "source": "/(index.html|flutter_bootstrap.js|flutter_service_worker.js|version.json|manifest.json)",
      "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
    },
    {
      "source": "/(assets|canvaskit)/(.*)",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=86400" }]
    }
  ]
}
```

Notes:

- Vercel serves existing files before applying `rewrites`, so the catch-all only hits
  unknown paths (deep links into the panel).
- The CSP is the one in `docs/guides/release.md`. The admin web makes no calls to Maps or FCM,
  so only the API and the storage host appear in `connect-src`/`img-src`.
- Flutter web does not fingerprint its file names (`main.dart.js` keeps its name between
  releases), so do **not** mark `main.dart.js` immutable; the one-day cache above covers
  only `assets/` and `canvaskit/`, which change rarely. Lower it if that is too long.

### 2.3 Deploy from a machine

```sh
npm i -g vercel
cd Frontend/apps/admin/build/web
cp ../../../../../deploy/vercel.json .   # wherever you keep the file from §2.2
vercel link                              # once: create/select the project, e.g. pao-admin
vercel deploy                            # preview
vercel deploy --prod                     # production
```

This uploads the static folder as-is; there is no Vercel build step, so the project's
framework preset must be "Other" with no build command. (`vercel deploy --prebuilt`
expects a `.vercel/output` directory produced by `vercel build`; for a plain static
folder, `vercel deploy` from inside it is the simpler form.)

### 2.4 Deploy from GitHub Actions

There is no deploy workflow in `.github/workflows` today. A job would:

1. Set up Flutter 3.47.7 (`subosito/flutter-action`, as `frontend.yml` does).
2. `tools/build-release.sh admin prod`.
3. Copy `vercel.json` into `Frontend/apps/admin/build/web`.
4. `npx vercel@<pinned version> deploy --prod --token "$VERCEL_TOKEN"` inside that
   folder, with `VERCEL_ORG_ID` and `VERCEL_PROJECT_ID` set (from `.vercel/project.json`
   after `vercel link`). These three would be new repository secrets.

### 2.5 Domains, previews, flavours

- Add the custom domain (e.g. `admin.pao.com.bd`) under Project → Domains and create
  the CNAME Vercel shows.
- The API's CORS check (`EdgeMiddleware` in
  `Backend/PAO.Infrastructure/Http/Edge/EdgeMiddleware.cs`) allows the origins listed in
  `ADMIN_CORS_ORIGIN`: one origin or a comma-separated list, each compared as an exact
  string. Write each with scheme and no path or trailing slash; the API refuses to start
  otherwise: `ADMIN_CORS_ORIGIN=https://admin.pao.com.bd`.
- Wildcards are not accepted, so a Vercel preview URL (`*.vercel.app`) must be listed
  by name to call an API. MVP rule (ADR-0036): production lists only the production
  admin origin; previews run against staging, whose `ADMIN_CORS_ORIGIN` lists the
  staging alias and, while needed, a fixed preview alias, e.g.
  `ADMIN_CORS_ORIGIN=https://admin-staging.pao.com.bd,https://pao-admin-preview.vercel.app`
  (assign the alias with `vercel alias`).
- Vercel environment variables do not reach the app: Flutter compiles
  `--dart-define` values into the JavaScript at build time, so a different API host
  means a different build.

## 3. Backend

### 3.1 Provision services

1. **Postgres (Neon).** Create a project in Singapore, database `pao`. Copy the
   connection string with `sslmode=require`. PostGIS and `pg_trgm` are created by the
   migrations; the role needs permission to create extensions (Neon's owner role has it).
   For Vercel Postgres the steps are the same (it is Neon underneath).
2. **Redis (Upstash).** Create a regional database in the same region; copy the
   `rediss://default:<password>@<host>:6379` URL.
3. **Storage (Cloudflare R2).** Create an API token with Object Read & Write on the two
   buckets. Endpoint `https://<account-id>.r2.cloudflarestorage.com`, region `auto`.
   The API creates `S3_BUCKET_PRIVATE` and `S3_BUCKET_PUBLIC` at start-up when missing
   (a bucket the worker created a moment earlier counts as present) and sets default
   encryption (`PutBucketEncryption`) on every start. R2 encrypts every object at rest
   itself and may not implement that call, so on R2 set `S3_ENSURE_ENCRYPTION=false`
   (ADR-0036). Create the buckets yourself first if the token cannot create them.
   On AWS S3: an IAM user limited to the two buckets, endpoint
   `https://s3.<region>.amazonaws.com`.
4. **Firebase.** Create one project; add the Android and iOS apps (§4.3); create a
   service account key (Project settings → Service accounts → Generate new private key)
   for the backend.
5. **SSL Wireless.** API token and SID for OTP SMS.

### 3.2 Environment variables

Every variable the .NET hosts read (`Backend/Docs/Config/variables.md`; mapped onto
configuration keys by `EnvironmentVariables`). The API and the
worker refuse to start on a missing or invalid value and list all problems in one log
line (`invalid configuration: …`). Give API, worker and migrate the same environment.

| Variable | Required | Example (prod) | Where it comes from |
|---|---|---|---|
| `APP_ENV` | yes in practice (default `dev`) | `prod` | `dev`, `test`, `staging` or `prod`. `prod` requires real SMS and push adapters. Never `test` outside CI. |
| `LOG_LEVEL` | no (default `info`) | `info` | `debug`, `info`, `warn`, `error` |
| `HTTP_ADDR` | no (default `:8080`) | `:8080` | Match the port your host routes to. The container health check probes `127.0.0.1:8080` and assumes the default. |
| `METRICS_ADDR` | no (default `:9090`) | `:9090` | Internal only; never expose publicly. The worker health check probes `127.0.0.1:9090`. |
| `DATABASE_URL` | **yes** | `postgres://user:pass@ep-xxx.ap-southeast-1.aws.neon.tech/pao?sslmode=require` | Neon / Vercel Postgres |
| `REDIS_URL` | **yes** | `rediss://default:pass@xxx.upstash.io:6379` | Upstash |
| `S3_ENDPOINT` | **yes** | `https://<account>.r2.cloudflarestorage.com` | R2 / S3 |
| `S3_PUBLIC_ENDPOINT` | no (defaults to `S3_ENDPOINT`) | same, or a custom domain | Host that signed URLs point to; must be reachable by the apps and in the admin CSP |
| `S3_REGION` | no (default `us-east-1`) | `auto` (R2) / `ap-southeast-1` (S3) | provider |
| `S3_ACCESS_KEY` | **yes** | `…` | R2 API token / IAM access key |
| `S3_SECRET_KEY` | **yes** | `…` | same |
| `S3_BUCKET_PRIVATE` | **yes** | `pao-prod-private` | your choice |
| `S3_BUCKET_PUBLIC` | **yes** | `pao-prod-public` | your choice |
| `JWT_SIGNING_KEY` | **yes** | base64 of 32 bytes | generate (§3.3) |
| `JWT_KEY_ID` | no (default `k1`) | `k202610` | your choice; change on rotation |
| `JWT_PREVIOUS_PUBLIC_KEYS` | no | empty on first deploy | `kid:base64pub,…`, only during rotation |
| `DATA_ENCRYPTION_KEY` | **yes** | base64 of 32 bytes | generate (§3.3); rotate with [`rotate-data-key.md`](../runbooks/rotate-data-key.md) |
| `DATA_ENCRYPTION_PREVIOUS_KEYS` | no | empty on first deploy | earlier data keys, comma-separated, newest first, original key last; only after a rotation |
| `ADMIN_CORS_ORIGIN` | no (default `http://localhost:5000`) | `https://admin.pao.com.bd` | the admin web origin, or a comma-separated list (§2.5) |
| `S3_ENSURE_ENCRYPTION` | no (default `true`) | `false` on R2 | `false` skips `PutBucketEncryption` for providers that encrypt at rest themselves |
| `SMS_ADAPTER` | no (default `console`); prod needs `sslwireless` | `sslwireless` | — |
| `SSLWIRELESS_API_TOKEN` | when `SMS_ADAPTER=sslwireless` | `…` | SSL Wireless |
| `SSLWIRELESS_SID` | when `SMS_ADAPTER=sslwireless` | `…` | SSL Wireless |
| `PUSH_ADAPTER` | no (default `log`); prod needs `fcm` | `fcm` | — |
| `FCM_CREDENTIALS_FILE` | this or `FCM_CREDENTIALS_JSON` when `PUSH_ADAPTER=fcm` | `/etc/secrets/fcm.json` | path to the Firebase service-account JSON, mounted as a secret file (Render "Secret Files"); wins when both are set |
| `FCM_CREDENTIALS_JSON` | this or `FCM_CREDENTIALS_FILE` when `PUSH_ADAPTER=fcm` | output of `base64 -w0 fcm.json` | the same JSON as a plain secret, raw or base64, for hosts without secret files (Fly, Railway) |
| `SEED_ADMIN_PASSWORD` | no | empty in prod | dev/staging only: password for the demo admins `seed` creates; ignored when `APP_ENV=prod` |
| `ADMIN_PASSWORD` | only for `migrate create-admin` | — | the first super admin's password (§3.5); set it for that one run, never on the API or worker |

### 3.3 Generate secrets

Both keys must decode (strict, padded base64) to exactly 32 bytes.

```sh
# Ed25519 seed for access tokens (EdDSA JWTs)
openssl rand -base64 32        # → JWT_SIGNING_KEY
# AES-256-GCM key for encrypted fields (NID numbers, TOTP secrets)
openssl rand -base64 32        # → DATA_ENCRYPTION_KEY
```

Use different values per environment. Store `DATA_ENCRYPTION_KEY` in a second, offline
place: losing it makes stored NID numbers and TOTP secrets unreadable. Change it only with
[`rotate-data-key.md`](../runbooks/rotate-data-key.md), which keeps the old key in
`DATA_ENCRYPTION_PREVIOUS_KEYS`. The JWT public key is derived from the
seed by the API; the command to print it, needed only for rotation, is in
[`rotate-jwt-keys.md`](../runbooks/rotate-jwt-keys.md).

### 3.4 Deploy on a container host (recommended)

The same image runs three ways:

| Service | Command / entry point | Port | Health check |
|---|---|---|---|
| `pao-migrate` (release job) | `/app/migrate up` | — | exits 0 |
| `pao-api` (web service) | default (`/app/api`) | 8080 public; 9090 private | `GET /healthz` (liveness), `GET /readyz` (DB, Redis, storage) or `/app/api healthcheck` |
| `pao-worker` (background worker) | `/app/worker` | 9090 private | `/app/worker healthcheck` or `GET :9090/healthz` |

**Render** (Docker): create a Web Service from the repo, root directory `Backend`,
Dockerfile `Backend/docker/Dockerfile`, port 8080, health check path `/readyz`, pre-deploy
command `/app/migrate up`. Create a Background Worker from the same repo with Docker
command `/app/worker`. Use an Environment Group for the variables in §3.2 and attach it
to both; add the FCM JSON as a Secret File (`FCM_CREDENTIALS_FILE`) or as the variable
`FCM_CREDENTIALS_JSON`.

**Fly.io**: `fly launch --no-deploy` in `Backend/` (Dockerfile `docker/Dockerfile`), then in `fly.toml` set
`[deploy] release_command = "/app/migrate up"`, `[http_service] internal_port = 8080`
with a check on `/readyz`, and `[processes] api = "" , worker = "/app/worker"` is not
possible because the image uses `ENTRYPOINT`; instead create a second Fly app for the
worker with `[experimental] entrypoint = ["/app/worker"]` (or the `[processes]`
equivalent with full commands). `fly secrets set KEY=value …` for §3.2.

**Railway**: two services from the repo with root `Backend` and Dockerfile `docker/Dockerfile`; on the worker set the
start command to `/app/worker`; on the API set the pre-deploy command to
`/app/migrate up` and the health check path to `/readyz`.

Build behind a TLS-intercepting proxy only: pass the CA as build secret `extra_ca`
(see the Dockerfile); hosted builders do not need it.

### 3.5 First deploy order

1. Provision Postgres, Redis, storage, Firebase and SMS (§3.1); fill the secret store
   (§3.2, §3.3).
2. Build and push the image: run the **backend-image** workflow (Actions → backend-image →
   Run workflow); it pushes `ghcr.io/<owner>/<repo>/pao-backend:<git-sha>` and prints the
   digest to deploy. By hand:
   `docker build -t <registry>/pao-backend:<git-sha> -f Backend/docker/Dockerfile Backend`
   (or let the host build it). Optionally scan it:
   `PAO_SCAN_IMAGE=<registry>/pao-backend:<git-sha> ./pao security`.
3. Migrate: run the image with `/app/migrate up`. It applies every module's migrations
   and exits 0.
4. Seed reference data: `/app/migrate seed`. It loads the service catalog
   (idempotent). In `staging` with `SEED_ADMIN_PASSWORD` set it also creates the demo
   admin users; in `prod` it creates none.
5. Create the first super admin, once, with the same environment plus `ADMIN_PASSWORD`
   (at least 12 characters, from your password manager; it is read from the environment
   so it never appears in argv or shell history):
   ```sh
   docker run --rm --env-file prod.env -e ADMIN_PASSWORD \
     --entrypoint /app/migrate <image> create-admin --email owner@pao.com.bd --name "PAO Owner"
   ```
   (Render: a one-off job; Fly: `fly ssh console -C "/app/migrate create-admin …"` after
   `fly secrets set ADMIN_PASSWORD=…`, then `fly secrets unset ADMIN_PASSWORD`.) It
   prints `created super admin`, or `already exists; nothing changed` when the email is
   taken, so repeating it is safe. The first sign-in at the admin web enrols TOTP before
   anything else; invite every other admin from the console (A-10).
6. Start the API; wait until `GET https://<api host>/readyz` returns 200.
7. Start the worker; its health check must pass.
8. Point DNS for the API host at the platform; TLS is issued by the platform.
9. Deploy the admin web (§2) with `ADMIN_CORS_ORIGIN` already set to its origin.
10. Sign in as the super admin, enrol TOTP, then run the smoke tests (§5).

Later releases follow [`docs/runbooks/deploy.md`](../runbooks/deploy.md): staging first,
production by image digest, migrate, roll API, roll worker, seed only when the release
notes say so. Migrations are forward-only.

### 3.6 Vercel Functions

Not possible for the API or the worker: Vercel Functions have no .NET runtime. Only the
admin web is hosted on Vercel (§2).

## 4. Mobile apps (customer and partner)

### 4.1 Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.47.7 stable (pinned in `.github/workflows/frontend.yml`) |
| JDK | 17 (Temurin in CI) |
| Android SDK | with the platform and build tools Gradle requests on first build |
| Xcode | 26 on macOS (CI runs `macos-26`) |
| CocoaPods | for the iOS build |

### 4.2 Flavours and app IDs

| Flavour | Customer Android / iOS | Partner Android / iOS | API (`config/<flavour>.json`) |
|---|---|---|---|
| dev | `bd.pao.pao_customer.dev` / `bd.pao.paoCustomer.dev` | `bd.pao.pao_partner.dev` / `bd.pao.paoPartner.dev` | emulator local stack |
| staging | `bd.pao.pao_customer.staging` / `bd.pao.paoCustomer.staging` | `bd.pao.pao_partner.staging` / `bd.pao.paoPartner.staging` | `https://api.staging.pao.com.bd` |
| prod | `bd.pao.pao_customer` / `bd.pao.paoCustomer` | `bd.pao.pao_partner` / `bd.pao.paoPartner` | `https://api.pao.com.bd` |

Application IDs cannot change once an app is on a store. Hostnames and support
contacts are placeholders until the owner confirms them.

### 4.3 Configuration values

All app configuration is compiled in with `--dart-define`; nothing is read at runtime.

| Key | Apps | Source | How it is passed |
|---|---|---|---|
| `PAO_FLAVOUR` | all | `config/<flavour>.json` | `--dart-define-from-file` (by the script) |
| `PAO_API_BASE_URL` | all | `config/<flavour>.json`; your API host | same |
| `PAO_SUPPORT_PHONE`, `PAO_SUPPORT_EMAIL` | customer, partner | `config/<flavour>.json` | same |
| `PAO_MAPS_API_KEY` | customer (Geocoding via `maps.googleapis.com`) | Google Cloud console → APIs & Services → Credentials; enable the Geocoding API; restrict to the package names / bundle IDs and SHA-256 certs | env var, forwarded by `build-release.sh` |
| `PAO_FCM_API_KEY`, `PAO_FCM_APP_ID`, `PAO_FCM_SENDER_ID`, `PAO_FCM_PROJECT_ID` | customer, partner | Firebase console → Project settings → Your apps (API key, App ID, Sender ID, Project ID) | env vars, forwarded by `build-release.sh`. Without `PAO_FCM_API_KEY` the app runs without push. |
| `PAO_FCM_APP_ID_<APP>_<PLATFORM>` | customer, partner | Firebase console → Your apps: the App ID of that platform's app, e.g. `PAO_FCM_APP_ID_CUSTOMER_ANDROID`, `PAO_FCM_APP_ID_PARTNER_IOS` | env vars; `build-release.sh` uses the one for the app and target (`ipa` → IOS, else ANDROID) in place of `PAO_FCM_APP_ID` when set |
| `PAO_PIN_SHA256` | all | computed from the live API certificate (below) | env var, forwarded by `build-release.sh` when set; empty leaves pinning off |
| `PAO_SENTRY_DSN` | all | Sentry project → Client Keys (DSN) | env var, forwarded by `build-release.sh` when set; empty leaves crash reporting off (errors stay on the device) |

**Firebase config files.** The apps do not use `google-services.json` or
`GoogleService-Info.plist`; they call `Firebase.initializeApp` with `FirebaseOptions`
built from the `PAO_FCM_*` defines (`lib/main.dart`). Do not add those files. For iOS
push, upload an APNs authentication key in Firebase (Project settings → Cloud Messaging)
and enable the Push Notifications capability in Xcode.

**Certificate pin.** `PAO_PIN_SHA256` is a comma-separated list of base64 SHA-256 hashes
of the API certificate's SubjectPublicKeyInfo (the key, not the certificate). Pinning is
active only in release builds and only when the value is set. Compute the live hash:

```sh
openssl s_client -connect api.pao.com.bd:443 -servername api.pao.com.bd </dev/null 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary | openssl base64
```

Always ship a second, backup pin (hash of a key you hold but do not use yet, or of the
issuing CA's intermediate key) next to the live one:

```sh
openssl pkey -in backup.key -pubout -outform der | openssl dgst -sha256 -binary | openssl base64
```

Managed platforms (Render, Fly, Railway, Vercel) renew certificates automatically and
usually generate a **new key** on renewal, which breaks a leaf-key pin. On such hosts,
pin the intermediate CA's key (take the second certificate from
`openssl s_client -showcerts`) plus a backup CA, or terminate TLS with a certificate
and key you control.

### 4.4 Android signing

1. Create the upload key once and keep it offline:
   ```sh
   keytool -genkeypair -v -keystore upload.jks -keyalg RSA -keysize 4096 -validity 10000 -alias upload
   ```
2. Enrol each app in Play App Signing.
3. Either set environment variables (what CI does):
   `PAO_ANDROID_KEYSTORE` (path to the `.jks`), `PAO_ANDROID_KEYSTORE_PASSWORD`,
   `PAO_ANDROID_KEY_ALIAS`, `PAO_ANDROID_KEY_PASSWORD`;
   or create `Frontend/apps/<app>/android/key.properties` (git-ignored):
   ```properties
   storeFile=/absolute/path/upload.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```
Without either, release builds are signed with the debug key and Play rejects them.

### 4.5 iOS signing

1. Register the bundle IDs from §4.2, an Apple Distribution certificate and an App Store
   provisioning profile per app; enable Push Notifications on the App IDs.
2. Set `DEVELOPMENT_TEAM` in Xcode.
3. Write an `ExportOptions.plist`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0"><dict>
     <key>method</key><string>app-store-connect</string>
     <key>teamID</key><string>ABCDE12345</string>
     <key>provisioningProfiles</key><dict>
       <key>bd.pao.paoCustomer</key><string>PAO Customer App Store</string>
     </dict>
   </dict></plist>
   ```
4. Export its path as `PAO_IOS_EXPORT_OPTIONS`; without it the script builds with
   `--no-codesign`.

### 4.6 Build

```sh
export PAO_MAPS_API_KEY=… PAO_FCM_API_KEY=… PAO_FCM_SENDER_ID=… PAO_FCM_PROJECT_ID=…
export PAO_FCM_APP_ID_CUSTOMER_ANDROID=… PAO_FCM_APP_ID_CUSTOMER_IOS=…   # one per platform and app
export PAO_PIN_SHA256="<live pin>,<backup pin>" PAO_SENTRY_DSN=…        # optional; empty = off
export PAO_BUILD_NUMBER=42                      # strictly increasing per store upload

tools/build-release.sh customer prod          # .aab → build/app/outputs/bundle/prodRelease/
tools/build-release.sh partner prod           # .aab
tools/build-release.sh partner staging apk    # APK for testers
PAO_IOS_EXPORT_OPTIONS=$PWD/ExportOptions.plist tools/build-release.sh customer prod ipa
```

The equivalent raw command:

```sh
cd Frontend/apps/customer
flutter build appbundle --release --flavor=prod \
  --dart-define-from-file=config/prod.json \
  --dart-define=PAO_MAPS_API_KEY="$PAO_MAPS_API_KEY" \
  --dart-define=PAO_FCM_API_KEY="$PAO_FCM_API_KEY" \
  --dart-define=PAO_FCM_APP_ID="$PAO_FCM_APP_ID" \
  --dart-define=PAO_FCM_SENDER_ID="$PAO_FCM_SENDER_ID" \
  --dart-define=PAO_FCM_PROJECT_ID="$PAO_FCM_PROJECT_ID" \
  --dart-define=PAO_PIN_SHA256="<live pin>,<backup pin>" \
  --dart-define=PAO_SENTRY_DSN="<dsn>" \
  --build-number="$PAO_BUILD_NUMBER" \
  --obfuscate --split-debug-info=build/symbols/prod
# iOS: flutter build ipa … --export-options-plist=ExportOptions.plist
```

Keep `build/symbols/<flavour>` for every release; crash stack traces cannot be read
without it.

### 4.7 Upload

- **Play Console:** create the app with the prod application ID, upload the `.aab` to
  Internal testing, complete Data safety, content rating and (partner) the
  `FOREGROUND_SERVICE_LOCATION` declaration, then promote with a staged rollout.
- **App Store Connect / TestFlight:** create the app with the bundle ID, then upload the
  `.ipa` from `build/ios/ipa/` with Transporter or
  `xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios --apiKey <key id> --apiIssuer <issuer id>`.
  Test in TestFlight, then submit with phased release.

The full store checklist is in [`docs/guides/release.md`](release.md#store-checklist).

### 4.8 CI secrets (`.github/workflows/frontend.yml`)

| Secret | Used for |
|---|---|
| `PAO_MAPS_API_KEY` | Maps define |
| `PAO_FCM_API_KEY`, `PAO_FCM_SENDER_ID`, `PAO_FCM_PROJECT_ID` | FCM defines |
| `PAO_FCM_APP_ID_CUSTOMER_ANDROID`, `PAO_FCM_APP_ID_CUSTOMER_IOS`, `PAO_FCM_APP_ID_PARTNER_ANDROID`, `PAO_FCM_APP_ID_PARTNER_IOS` | FCM App ID per platform and app (preferred) |
| `PAO_FCM_APP_ID_customer`, `PAO_FCM_APP_ID_partner` | fallback FCM App ID per app, used when the per-platform secret is missing |
| `PAO_PIN_SHA256` | certificate pins (comma-separated); missing → pinning off |
| `PAO_SENTRY_DSN` | Sentry DSN; missing → crash reporting off |
| `PAO_ANDROID_KEYSTORE_BASE64`, `PAO_ANDROID_KEYSTORE_PASSWORD`, `PAO_ANDROID_KEY_ALIAS`, `PAO_ANDROID_KEY_PASSWORD` | Android signing (CI decodes the keystore and sets `PAO_ANDROID_KEYSTORE`) |
| `PAO_IOS_CERT_P12_BASE64`, `PAO_IOS_CERT_PASSWORD` | iOS distribution certificate |
| `PAO_IOS_PROFILE_BASE64_customer`, `PAO_IOS_PROFILE_BASE64_partner` | provisioning profiles |
| `PAO_IOS_EXPORT_OPTIONS_BASE64_customer`, `PAO_IOS_EXPORT_OPTIONS_BASE64_partner` | `ExportOptions.plist` per app |

CI sets `PAO_BUILD_NUMBER` to the run number and passes every secret above that is set
to both the Android and the iOS builds. Firebase registers one app per application ID,
so the dev and staging flavours share the prod App ID in CI and get no push; that is the
MVP rule (ADR-0036). CI does not upload to the stores; download the artifacts and upload
them by hand (§4.7).

## 5. After deploying

### Smoke tests

```sh
curl -fsS https://api.pao.com.bd/healthz
curl -fsS https://api.pao.com.bd/readyz
# CORS preflight from the admin origin must echo it back
curl -si -X OPTIONS https://api.pao.com.bd/v1/auth/refresh \
  -H 'Origin: https://admin.pao.com.bd' -H 'Access-Control-Request-Method: GET' \
  | grep -i access-control-allow-origin
curl -sI https://admin.pao.com.bd | grep -i content-security-policy
```

Then by hand: sign in to the admin panel; on a release build of each app, sign in with
OTP (a real SMS arrives), search nearby providers, receive a push; upload a partner
document and open it from the admin panel (signed storage URL). Check the worker logs
show no `invalid configuration` and the outbox is draining.

### Pinning warning

A release build with a wrong or stale `PAO_PIN_SHA256` cannot reach the API at all, and
only a store update fixes it. Before changing the API's TLS key, host or CDN: ship an
app release that already contains the new pin, wait until most users have updated, and
only then switch. Check the live hash with the `openssl` command in §4.3 after every
certificate change.

### Rollback

- Backend: redeploy the previous image digest for API then worker; never run
  migrations backwards ([`runbooks/rollback.md`](../runbooks/rollback.md)).
- Admin web: Vercel → Deployments → previous deployment → "Promote to Production"
  (or `vercel rollback`).
- Mobile: halt the Play staged rollout / pause the App Store phased release; ship a
  fixed build with a higher build number.

### Troubleshooting

| Symptom | Likely cause |
|---|---|
| API exits with `invalid configuration: …` | Missing or malformed variable; the message lists all of them. Keys must be padded base64 of 32 bytes. |
| `production needs real SMS_ADAPTER and PUSH_ADAPTER` | `APP_ENV=prod` with `console`/`log` adapters |
| `prepare storage` at start-up | Wrong S3 endpoint/credentials, or the token may not create buckets or set encryption |
| `/readyz` fails, `/healthz` passes | Database, Redis or storage unreachable (TLS: use `sslmode=require` / `rediss://`) |
| Admin panel: network errors, CORS in console | `ADMIN_CORS_ORIGIN` not exactly the browser origin, or a preview URL |
| Admin panel: blank page, CSP errors | API or storage host missing from `connect-src`/`img-src` |
| Admin deep links 404 | `vercel.json` rewrites missing from the uploaded folder |
| App cannot connect in release, works in debug | Pin mismatch |
| No push on iOS | APNs key not uploaded to Firebase, or the iOS app uses the Android `PAO_FCM_APP_ID` |

## Gaps to close before launch

Everything that can be done in code is done (ADR-0036). What remains needs the owner's
accounts, secrets or decisions; the values to confirm are collected in
[`launch-values.md`](launch-values.md).

1. **Container host for the API and worker** (no .NET runtime on Vercel). Create the two
   services on Render, Fly.io or Railway exactly as in §3.4.
2. **Backend secrets.** Generate `JWT_SIGNING_KEY` and `DATA_ENCRYPTION_KEY` (§3.3), store
   both offline as well, and fill §3.2 in the host's secret store.
3. **Managed services.** Create Neon Postgres, Upstash Redis and the R2 (or S3) buckets
   and token (§3.1); on R2 set `S3_ENSURE_ENCRYPTION=false`.
4. **Firebase.** Create the project; add the four apps (customer/partner × Android/iOS)
   with the prod IDs of §4.2; generate a service-account key and set it as
   `FCM_CREDENTIALS_FILE` or `FCM_CREDENTIALS_JSON` (`base64 -w0 key.json`); upload the
   APNs key (Project settings → Cloud Messaging). Add `PAO_FCM_API_KEY`,
   `PAO_FCM_SENDER_ID`, `PAO_FCM_PROJECT_ID` and the four `PAO_FCM_APP_ID_<APP>_<PLATFORM>`
   values as GitHub secrets (Settings → Secrets and variables → Actions).
5. **SSL Wireless** API token and SID (§3.1 item 5).
6. **First super admin.** After the first `migrate up`, run `migrate create-admin` once
   (§3.5 step 5) and enrol TOTP at the first sign-in.
7. **DNS and domains.** Buy or confirm the domain, point the API and admin hosts at the
   platforms (§2.5, §3.5), then set `ADMIN_CORS_ORIGIN`.
8. **Certificate pins and Sentry (optional).** Once the API host serves its real
   certificate, compute the pins (§4.3) and add `PAO_PIN_SHA256`; create a Sentry
   project and add `PAO_SENTRY_DSN`. Empty secrets leave both features off.
9. **Android signing.** Create the upload key (§4.4 step 1), enrol both apps in Play App
   Signing, then add `PAO_ANDROID_KEYSTORE_BASE64` (`base64 -w0 upload.jks`),
   `PAO_ANDROID_KEYSTORE_PASSWORD`, `PAO_ANDROID_KEY_ALIAS` and
   `PAO_ANDROID_KEY_PASSWORD` as GitHub secrets.
10. **iOS signing.** In the Apple Developer account register the two prod bundle IDs with
    Push Notifications, create an Apple Distribution certificate (export it as `.p12`) and
    an App Store profile per app, write `ExportOptions.plist` per app (§4.5), then add
    `PAO_IOS_CERT_P12_BASE64`, `PAO_IOS_CERT_PASSWORD`,
    `PAO_IOS_PROFILE_BASE64_customer|partner` and
    `PAO_IOS_EXPORT_OPTIONS_BASE64_customer|partner` (each `base64 -i <file>`).
11. **Store listings and upload.** Create both apps in Play Console and App Store Connect,
    complete the store checklist in [`release.md`](release.md#store-checklist), download
    the signed CI artifacts and upload them by hand (§4.7). Store upload from CI is not
    part of the MVP.
12. **Placeholders.** Confirm or replace the hostnames, support contacts and app icons
    listed in [`launch-values.md`](launch-values.md).
