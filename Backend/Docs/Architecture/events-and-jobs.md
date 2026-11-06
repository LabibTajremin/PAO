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
  `JobScheduler` runs each under `pg_try_advisory_lock(7041, hashtext(name))`, the
  lock earlier releases took too, so one worker runs a job at a time. Jobs are listed in
  [Operations/jobs.md](../Operations/jobs.md).

## Running the jobs in the API

The worker host (`PAO.Worker`) runs the relay and the jobs through
`WorkerServices.AddBackgroundJobs`. With `JOBS_IN_API=true` (`Jobs:RunInApi`) the API host
calls the same method from `AddBackgroundJobsInApi`
(`PAO.Core/Registration/BackgroundJobsInApiRegistration.cs`), so both hosts register one
identical set: the `EventBus` with every `IEventSubscriptions`, `OutboxRelay`,
`OutboxMaintenance`, every `IScheduledJob`, `JobScheduler` and the hosted `WorkerLoop`. It
is meant for the MVP on a single free instance (ADR-0036 §14). Off, the API registers none
of them.

- **Start and stop.** `WorkerLoop` is an ordinary hosted service, so it starts once the
  API has passed `PlatformStartup.Prepare` and is cancelled when the API stops: the relay
  and the scheduler leave their loops and a running job gets the cancellation token,
  within the host's shutdown timeout.
- **Health.** `/readyz` checks only the database, Redis and storage, never the jobs. The
  worker keeps its own `/healthz` on `METRICS_ADDR`. The job and outbox metrics
  (`pao_job_*`, `pao_outbox_*`) are served from the API's metrics port.
- **Start-up line.** The API logs `background jobs: in api` when it runs them, otherwise
  `background jobs: in worker`; the worker always logs `background jobs: in worker` and
  warns when it also sees `JOBS_IN_API=true`.
- **Worker and API together.** Nothing is processed twice. Each job run holds its
  advisory lock and jobs are idempotent sweeps (reminders are recorded once each); the
  relay claims rows with `FOR UPDATE SKIP LOCKED` and marks them published in the same
  transaction, so a second relay never sees a row the first holds; handlers stay
  idempotent (`processed_events`, one commission per booking) for a redelivery after a
  crash. These are the guarantees that let several workers overlap during a release. The
  cost: every sweep runs twice as often, and per-aggregate order is strict only within
  one relay. So run either the worker or `JOBS_IN_API=true`.
