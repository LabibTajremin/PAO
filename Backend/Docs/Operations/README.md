# Operations

## Hosts and image

One image (`Backend/docker/Dockerfile`, built from `Backend/`) with three entry points:

| Entry point | Host | Health check |
|---|---|---|
| `/app/api` | `PAO.Core` — contract on `HTTP_ADDR`, metrics on `METRICS_ADDR`; with `JOBS_IN_API=true` also the relay and jobs ([below](#where-the-background-jobs-run)) | `/app/api healthcheck` (GET :8080/healthz) |
| `/app/worker` | `PAO.Worker` — relay, jobs; liveness and metrics on `METRICS_ADDR` | `/app/worker healthcheck` (GET :9090/healthz) |
| `/app/migrate` | `PAO.Migrator` — `up`, `seed` (loads `Seed/catalog.yaml` through `SeedCommand`: the catalog, and the demo admins outside prod when `SEED_ADMIN_PASSWORD` is set), `perf-seed N` (`PerfSeedCommand`: N online electricians and a customer-token fixture as JSON; refuses prod), `create-admin --email E --name N` (`CreateAdminCommand`), `reencrypt` (`ReencryptCommand`), `bundle [--check]` (`BundleCommand`: writes or checks `DB Changes/bundle/schema.sql` and `seed.sql`, no database needed; see [Database](../Database/README.md)) | — |

`infra/docker-compose.yml` builds the api, worker and migrate services from this image.

## Where the background jobs run

By default only the worker runs the outbox relay and the [jobs](jobs.md). For a
deployment with a single service (the MVP on Render's free plan) set `JOBS_IN_API=true`
on the API and run no worker: the API then registers exactly the worker's services
(`AddBackgroundJobsInApi`, [events and jobs](../Architecture/events-and-jobs.md#running-the-jobs-in-the-api))
and stops them gracefully with itself. Check the start-up line: `background jobs: in api`
on the API, or `background jobs: in worker`. Running both is safe (advisory locks,
`SKIP LOCKED`) but wasteful; run one. To go back to a worker, start the worker service,
then set `JOBS_IN_API=false` (or remove it) on the API and redeploy it
([ADR-0036](../../../docs/adr/0036-mvp-launch-defaults.md) §14).

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
  naming each failed dependency (database, redis, storage); it never depends on the
  background jobs, even when the API runs them.
- Prometheus metrics (prometheus-net) keep their established names: `pao_http_*`, `pao_job_*`,
  `pao_outbox_*`, plus .NET runtime metrics.

## Logs

Serilog writes one JSON object per line (`time`, `level`, `msg`, properties, `err`) to
stdout and to `Logs/<yyyy-MM-dd>/pao-<host>.log` (Asia/Dhaka date). `request_id` and
`user_id` are attached to every line of a request.

See also [jobs](jobs.md).
