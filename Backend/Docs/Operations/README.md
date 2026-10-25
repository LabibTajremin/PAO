# Operations

## Hosts and image

One image (`Backend/docker/Dockerfile`, built from `Backend/`) with three entry points:

| Entry point | Host | Health check |
|---|---|---|
| `/app/api` | `PAO.Core` — contract on `HTTP_ADDR`, metrics on `METRICS_ADDR` | `/app/api healthcheck` (GET :8080/healthz) |
| `/app/worker` | `PAO.Worker` — relay, jobs; liveness and metrics on `METRICS_ADDR` | `/app/worker healthcheck` (GET :9090/healthz) |
| `/app/migrate` | `PAO.Migrator` — `up`, `seed` (loads `Seed/catalog.yaml` through `SeedCommand`: the catalog, and the demo admins outside prod when `SEED_ADMIN_PASSWORD` is set), `perf-seed N` (`PerfSeedCommand`: N online electricians and a customer-token fixture as JSON; refuses prod) | — |

`infra/docker-compose.yml` builds the api, worker and migrate services from this image.

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
