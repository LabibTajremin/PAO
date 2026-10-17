# Deploy the backend

**When:** a commit on `main` has passed CI (backend, contract, e2e and frontend
workflows) and is to go to staging, then production.

**You need:** deploy access to the container platform, the image registry and the
secret store; the PAO dashboards open (`ops/grafana/dashboards`).

## Rules

- Production gets only images that ran on staging first, by digest, not by tag.
- Migrations are forward-only (`/app/migrate` has no `down`). A migration must keep the
  previous release working (expand, then contract in a later release): add columns as
  nullable or with defaults, never rename or drop something the running release reads.
  This is what makes [rollback.md](rollback.md) a pure image swap.
- No deploys between 18:00 and 22:00 Asia/Dhaka (evening booking peak) or on Fridays
  unless fixing an incident.

## Steps

1. **Build and tag.** `docker build -t <registry>/pao-backend:<git-sha> backend` and push.
   Note the digest. Scan it: `PAO_SCAN_IMAGE=<registry>/pao-backend:<git-sha> ./pao security`.
2. **Check the environment.** Compare the release's `.env.example` with the target's
   variables; add new ones to the secret store first. The API refuses to start on a
   missing or invalid variable and lists every problem in one log line
   (`invalid configuration: …`).
3. **Back up.** Take an on-demand database snapshot (managed Postgres) or run the backup
   job from [restore-database.md](restore-database.md#backups). Write the snapshot id
   in the deploy log.
4. **Migrate.** Run the new image once with the entry point `/app/migrate up` and the
   production environment. It applies pending migrations per module and exits 0. If it
   fails, stop: the old release keeps running against the old schema; read the error,
   fix forward.
5. **Roll the API.** Replace instances one at a time (rolling update, max one
   unavailable). The platform health check is `/app/api healthcheck` or `GET /healthz`;
   route traffic only after `GET /readyz` answers 200.
6. **Roll the worker.** Replace the worker instances. Several may run at once (jobs take
   an advisory lock, the outbox relay uses `SKIP LOCKED`), so overlap is safe.
7. **Seed reference data** only when the release notes say the catalog or settings
   changed: `/app/migrate seed` (idempotent).

## Verify (15 minutes)

- PAO API dashboard: 5xx rate under 0.5%, p95 latency at its usual level, nearby search
  p95 under 300 ms.
- PAO worker dashboard: oldest pending outbox event under 5 s, no job failures, no new
  dead letters.
- PAO booking funnel: bookings still move from requested to accepted.
- Smoke test by hand on staging: sign in to each app, search nearby providers, open the
  admin dashboard.

If any check fails and the cause is not obvious within 10 minutes, roll back.

## Apps and admin web

Mobile and admin web builds follow `docs/release.md`. The apps must keep working with
the previous backend for as long as old app versions are in use: the API contract
(`api/openapi.yaml`) only grows; removing a field needs a new API version.
