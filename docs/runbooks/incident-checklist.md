# Incident checklist

Use it when an alert fires (infra/ops/prometheus/rules/pao.yml) or users report a problem.
Work top to bottom; write every step with its time in the incident channel.

## 1. Take charge (first 5 minutes)

- [ ] One person is **incident lead**; they decide, others investigate.
- [ ] Post: what is broken, since when, who is affected, severity:
  - **SEV1:** customers cannot book or providers cannot receive jobs; data exposed.
  - **SEV2:** a feature or one user group is broken; error rate above 2%.
  - **SEV3:** degraded but working (slow search, delayed notifications).
- [ ] SEV1: call the owner. Data exposure (documents, NID, phone numbers): also start
      section 5 at once.

## 2. Look (next 10 minutes)

- [ ] **Recent change?** Last deploy, settings change in the admin console (audit log),
      key rotation, infrastructure change. A deploy in the last hour → roll back first
      ([rollback.md](rollback.md)).
- [ ] **PAO API dashboard:** which routes fail (5xx by route), latency, 401/429 spikes.
- [ ] **PAO worker dashboard:** job failures, outbox lag, dead letters.
- [ ] **Health:** `GET /readyz` names the dependency that does not answer
      (`database`, `redis`, `storage`).
- [ ] **Logs:** structured JSON; follow one failing request by `request_id`. Unexpected
      errors are logged as `500 INTERNAL` by the error filter; job errors as
      `job failed` with the `job` field.
- [ ] **App crashes:** the Sentry projects for the customer, partner and admin apps.
- [ ] **Third parties:** SMS gateway (OTP sign-in fails), FCM (no pushes), maps.

## 3. Mitigate (stop the harm before finding the cause)

| Symptom | First action |
|---|---|
| bad deploy | [rollback.md](rollback.md) |
| database down or full | provider console; scale storage; failover to the replica |
| Redis down | sign-in, rate limits and presence fail; restart or fail over Redis. Nothing is lost that Postgres cannot rebuild; providers go online again |
| SMS gateway down | switch `SMS_ADAPTER` only if a second gateway is configured; otherwise post a status message in the apps' store listing and social channels |
| API overloaded | scale API instances; check for one abusive client in 429s by route |
| worker down or outbox lagging | restart the worker; check `PaoJobFailing` and the logs for the stuck module |
| leaked signing key | [rotate-jwt-keys.md](rotate-jwt-keys.md#emergency-rotation-key-leaked) |
| lost or damaged data | stop the worker, then [restore-database.md](restore-database.md) |

### Dead-lettered events

An event is dead-lettered after ten failed deliveries (`PaoOutboxDeadLetters`). It is
kept in `<module>.outbox` with `dead = true` and `last_error`. After the cause is fixed
and deployed, replay it; handlers are idempotent, so subscribers that already
succeeded skip it:

```sql
SELECT id, event_name, attempts, last_error FROM booking.outbox WHERE dead;
UPDATE booking.outbox SET dead = false, attempts = 0, next_attempt_at = now()
WHERE dead AND id = '<event id>';
```

### A scheduled job keeps failing

Jobs are idempotent sweeps, so a fixed release catches up on its next run. Daily jobs
(`verification.expire_documents` 02:00, `verification.expiry_reminders` 09:00,
`media.purge_orphans` 03:30, `outbox.purge_published` 03:00) only run once a day: if a
run was missed, restart the worker after the fix and check the next run, or ask an
engineer to run the sweep once by hand.

## 4. Resolve

- [ ] The alert has cleared and the dashboards are back to normal for 30 minutes.
- [ ] Users who were affected are told (in-app message or SMS for bookings that failed).
- [ ] Post "resolved" with the time.

## 5. Personal data incidents

- [ ] Contain: revoke the access (ban the admin account, rotate the leaked key, make the
      bucket private).
- [ ] Find out what was exposed: `audit.entries` records every document view with who and
      when; S3 access logs for direct object access.
- [ ] The owner decides on notifying affected users and the authorities as Bangladeshi
      law requires; keep a written record of the decision.

## 6. Afterwards (within 3 working days)

- [ ] Incident note: timeline, impact (bookings lost, users affected), root cause, why
      monitoring or tests did not catch it earlier.
- [ ] One follow-up task per cause, with an owner; a test or alert for each.
