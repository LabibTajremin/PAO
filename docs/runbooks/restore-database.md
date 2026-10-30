# Back up and restore the database

PRD §11 asks for daily database backups with a tested restore. PostgreSQL is the only
system of record: Redis can be rebuilt (users sign in again, presence refills within a
minute) and S3 objects are versioned by the storage provider.

## Backups

Two independent layers, so one mistake cannot remove both:

1. **Managed point-in-time recovery** (WAL archiving), retention 7 days at least. This is
   the normal restore path: it can return to any second in the window.
2. **A daily logical dump** at 01:30 Asia/Dhaka (before the 02:00 expiry job), kept 30
   days in a separate, versioned, private bucket with object lock:

   ```sh
   pg_dump "$DATABASE_URL" -Fc --no-owner -f "pao-$(date -u +%Y%m%dT%H%MZ).dump"
   ```

   The dump holds PostGIS, every module schema and the `public.goose_<module>` migration
   tables. It contains personal data (encrypted NID numbers, phone numbers): the bucket
   is encrypted and readable only by the backup role and the on-call lead.

Before each deploy, take an on-demand snapshot as well ([deploy.md](deploy.md)).

## Restore drill (prove the backups work)

`./pao ops restore-test` dumps the running dev stack's database inside an exported
snapshot, restores the dump into a scratch database (`pao_restore_drill`) on the same
server and compares every application table's row count and every module's latest
migration version. It fails on any difference and drops the scratch database at the end.
`./pao ops restore-test e2e` does the same on the end-to-end stack; CI runs it after the
API journeys (`.github/workflows/e2e.yml`), so every change proves a populated database
survives a dump and restore.

Monthly, in staging: restore last night's production dump into a new staging instance
with the steps below, point a staging API at it, sign in to the admin console and open a
provider's verification record. Record the time it took (the restore time objective).

## Restore

**When:** data is lost or damaged (bad migration, operator error, storage failure).
Restoring discards every write after the restore point: get the owner's go-ahead and
announce the downtime.

1. **Stop writers.** Scale the API and the worker to zero (or put the API behind the
   maintenance page). Note the time of the last good state.
2. **Restore into a new instance**, never over the damaged one (keep it for analysis):
   - Point-in-time: create a new instance from the managed backup at the last good time.
   - From a dump: create an empty PostgreSQL 16 + PostGIS 3 database, then
     ```sh
     pg_restore -d "$NEW_DATABASE_URL" --no-owner --exit-on-error pao-<stamp>.dump
     ```
3. **Check the restored database:**
   ```sh
   psql "$NEW_DATABASE_URL" -At -f tools/ops/fingerprint.sql > restored.txt
   ```
   Every module's `migration goose_<module>` line must show the version of the release
   you will run (compare with `Backend/DB Changes/<module>/`); table counts must be
   plausible (bookings, providers and accounts close to the dashboard's last figures).
4. **Run migrations** if the restore point predates the current release:
   `/app/migrate up` with `DATABASE_URL` set to the new instance.
5. **Point the services at it:** update `DATABASE_URL` in the secret store; start the
   worker, then the API. Check `/readyz`.
6. **Redis:** flush the `pao:{env}:cache:*` keys (catalog, settings, dashboard caches
   may describe newer data). Sessions can stay: refresh tokens unknown to the restored
   data are harmless, as accounts are looked up in Postgres.
7. **Outbox:** events written after the restore point are gone, so notifications for
   them never go out. Events still pending in the restored outboxes are delivered once
   more; handlers are idempotent (`processed_events`).
8. **Tell users** whose bookings fell after the restore point (from the damaged
   instance: `booking.bookings` with `created_at` after it) and recreate what matters.

## Afterwards

Keep the damaged instance for at least a week, write the incident note and schedule the
fix that makes the cause impossible.
