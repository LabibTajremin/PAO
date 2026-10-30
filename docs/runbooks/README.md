# Runbooks

Step-by-step procedures for running PAO in staging and production. Each one says when
to use it, what you need, the steps and how to check the result.

| Runbook | Use it when |
|---|---|
| [deploy.md](deploy.md) | shipping a new backend version |
| [rollback.md](rollback.md) | a deploy makes things worse |
| [rotate-jwt-keys.md](rotate-jwt-keys.md) | yearly, or at once if the signing key may have leaked |
| [rotate-data-key.md](rotate-data-key.md) | someone with secret-store access leaves, or `DATA_ENCRYPTION_KEY` may have leaked |
| [restore-database.md](restore-database.md) | data is lost or damaged; also the monthly restore drill |
| [incident-checklist.md](incident-checklist.md) | an alert fires or users report an outage |

Related: [../verification.md](../guides/verification.md) (the verification team's procedure),
[../../infra/ops/README.md](../../infra/ops/README.md) (dashboards and alert rules).

## The system in one paragraph

One Docker image (`Backend/docker/Dockerfile`) with three entry points: `/app/api` (stateless
HTTP API on `:8080`, scale horizontally), `/app/worker` (outbox relay and scheduled
jobs; one or more instances, jobs take an advisory lock) and `/app/migrate`
(`up` applies migrations, `seed` loads reference data, `create-admin` makes the first
super admin, `reencrypt` moves encrypted fields to the current data key). State lives in PostgreSQL 16 +
PostGIS, Redis 7 (sessions, refresh tokens, rate limits, presence) and S3 (documents,
photos). Every setting comes from environment variables (`.env.example` lists them);
secrets come from the deployment's secret store, never from the repository.
API and worker serve `/metrics` on `METRICS_ADDR` (`:9090`, internal only); the API
serves `/healthz` (process up) and `/readyz` (database, Redis and storage reachable).
