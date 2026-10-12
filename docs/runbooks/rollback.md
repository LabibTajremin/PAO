# Roll back a deploy

**When:** after a deploy the error rate, latency or a core flow (sign-in, nearby search,
booking) is worse, and a fix is not minutes away. Decide quickly; roll back first and
investigate after.

## Steps

1. **Announce** in the incident channel: "rolling back backend <new-sha> → <old-sha>".
2. **Roll the API back** to the previous image digest (the one in the last deploy log),
   one instance at a time, waiting for `GET /readyz` = 200 on each.
3. **Roll the worker back** to the same digest.
4. **Do not run migrations.** Migrations are forward-only and every release keeps the
   previous one working ([deploy.md](deploy.md#rules)), so the old image runs on the new
   schema. The `goose_<module>` tables keep the new versions; the next deploy skips them.
5. **Check** the dashboards as in [deploy.md](deploy.md#verify-15-minutes).

## When an image rollback is not enough

- **A migration broke data** (wrong backfill, dropped column): stop the worker so no
  events spread the damage, then follow [restore-database.md](restore-database.md)
  (point-in-time restore to just before the migration started; the deploy log has the
  time). Restoring loses every write after that point; get the owner's go-ahead.
- **A migration broke the old release** (a rule in deploy.md was missed): fix forward
  with a new migration that restores compatibility, deployed with the old code.
- **Events were dead-lettered** by the bad release: see
  [incident-checklist.md](incident-checklist.md#dead-lettered-events) to replay them
  once the fixed release runs.

## Afterwards

Write a short incident note (what changed, impact, timeline, why the gates did not catch
it) and add the missing test before the fix is redeployed.
