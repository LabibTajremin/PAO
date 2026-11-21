# infra

Everything that runs PAO's services outside the code: the local Docker stack, the stack the
end-to-end tests use, monitoring and the security scanners.

| Path | What it is |
|---|---|
| `docker-compose.yml` | The local stack `./pao up` starts: Postgres+PostGIS, Redis, S3-compatible storage, the API, the worker and a one-shot migrator |
| `e2e/` | A fresh, throwaway copy of the stack for the journeys (`e2e/stack.sh`; `./pao test e2e` starts it for you) |
| `ops/` | Prometheus alert rules and Grafana dashboards; `./pao ops check` validates them |
| `security/` | Settings for gitleaks, osv-scanner and trivy, which `./pao security` runs |

You rarely edit `docker-compose.yml` directly; settings come from `.env` (copied from
`.env.example` by `./pao setup`).
