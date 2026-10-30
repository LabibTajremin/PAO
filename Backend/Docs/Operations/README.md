# Operations

## Hosts and image

One image (`Backend/docker/Dockerfile`, built from `Backend/`) with three entry points:

| Entry point | Host | Health check |
|---|---|---|
| `/app/api` | `PAO.Core` — contract on `HTTP_ADDR`, metrics on `METRICS_ADDR` | `/app/api healthcheck` (GET :8080/healthz) |
| `/app/worker` | `PAO.Worker` — relay, jobs; liveness and metrics on `METRICS_ADDR` | `/app/worker healthcheck` (GET :9090/healthz) |
| `/app/migrate` | `PAO.Migrator` — `up`, `seed` (loads `Seed/catalog.yaml` through `SeedCommand`: the catalog, and the demo admins outside prod when `SEED_ADMIN_PASSWORD` is set), `perf-seed N` (`PerfSeedCommand`: N online electricians and a customer-token fixture as JSON; refuses prod), `create-admin --email E --name N` (`CreateAdminCommand`), `reencrypt` (`ReencryptCommand`) | — |

`infra/docker-compose.yml` builds the api, worker and migrate services from this image.

## First admin

`/app/migrate create-admin --email owner@pao.com.bd --name "PAO Owner"` with the host's
environment plus `ADMIN_PASSWORD` (≥ 12 characters; read from the environment so it stays
out of argv) creates one `super_admin`, in production too. An existing email is left
alone (exit 0, `already exists; nothing changed`); a missing password exits 1, malformed
arguments print the usage and exit 2. TOTP enrolment happens at the first sign-in.
Run it once after the first `migrate up` (`docs/guides/deployment.md` §3.5, ADR-0036).

## Data key rotation

`/app/migrate reencrypt` rewrites `identity.admin_credentials.totp_secret_enc` and
`verification.nid_records.nid_ciphertext` under `DATA_ENCRYPTION_KEY`, decrypting with
any key in `DATA_ENCRYPTION_PREVIOUS_KEYS`; rows already current are skipped, all in one
transaction. Procedure: `docs/runbooks/rotate-data-key.md`.

## Health and metrics

- `GET /healthz`: 200 while the process serves. `GET /readyz`: 200 `{status: ok}` or 503
  naming each failed dependency (database, redis, storage).
- Prometheus metrics (prometheus-net) keep their established names: `pao_http_*`, `pao_job_*`,
  `pao_outbox_*`, plus .NET runtime metrics.

## Logs

Serilog writes one JSON object per line (`time`, `level`, `msg`, properties, `err`) to
stdout and to `Logs/<yyyy-MM-dd>/pao-<host>.log` (Asia/Dhaka date). `request_id` and
`user_id` are attached to every line of a request.

See also [jobs](jobs.md).
