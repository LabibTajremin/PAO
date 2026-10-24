# Events and jobs

- `OutboxWriter` appends an event (camelCase JSON, `name` = `area.EventName`) to
  `<schema>.outbox` through the caller's DbContext, inside its transaction.
- The worker's `OutboxRelay` reads every outbox module of `DB Changes/modules.json` with
  `FOR UPDATE SKIP LOCKED`, dispatches to the in-process `EventBus`, keeps per-aggregate
  order, backs off exponentially (2^n s, at most 5 min) and dead-letters after 10 attempts.
- Subscribers are registered by each area through `IEventSubscriptions`;
  `IdempotentEventHandler` records `(handler, event_id)` in `<schema>.processed_events` in
  the same transaction, so redelivery is harmless.
- Periodic jobs implement `IScheduledJob` (`JobSchedule.Every` or `DailyAt` Asia/Dhaka).
  `JobScheduler` runs each under `pg_try_advisory_lock(7041, hashtext(name))`, the NestJS
  lock, so one worker of either backend runs a job at a time. Jobs are listed in
  [Operations/jobs.md](../Operations/jobs.md).
