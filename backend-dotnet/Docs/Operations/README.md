# Operations

## Hosts and image

One image (`backend-dotnet/docker/Dockerfile`, built from `backend-dotnet/`) with three entry points, like the NestJS image:

| Entry point | Host | Health check |
|---|---|---|
| `/app/api` | `PAO.Core` — contract on `HTTP_ADDR`, metrics on `METRICS_ADDR` | `/app/api healthcheck` (GET :8080/healthz) |
| `/app/worker` | `PAO.Worker` — relay, jobs; liveness and metrics on `METRICS_ADDR` | `/app/worker healthcheck` (GET :9090/healthz) |
| `/app/migrate` | `PAO.Migrator` — `up`, `seed` (loads `Seed/catalog.yaml` through `SeedCommand`; `perf-seed` returns with the Merchant area) | — |

`docker-compose.yml` still builds the NestJS image; switching it is part of cut-over (task 8).

## Health and metrics

- `GET /healthz`: 200 while the process serves. `GET /readyz`: 200 `{status: ok}` or 503
  naming each failed dependency (database, redis, storage).
- Prometheus metrics (prometheus-net) keep the NestJS names: `pao_http_*`, `pao_job_*`,
  `pao_outbox_*`, plus .NET runtime metrics.

## Logs

Serilog writes one JSON object per line (`time`, `level`, `msg`, properties, `err`) to
stdout and to `Logs/<yyyy-MM-dd>/pao-<host>.log` (Asia/Dhaka date). `request_id` and
`user_id` are attached to every line of a request.

See also [jobs](jobs.md).
