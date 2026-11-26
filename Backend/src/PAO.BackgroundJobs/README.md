# PAO.BackgroundJobs

The scheduled jobs and the outbox relay loop, hosted by the worker (or by the API when `JOBS_IN_API` is on).

Every job is listed in `docs/Operations/jobs.md`; a gate test fails if one is missing.

## Open these first

- `WorkerServices.cs`: everything this project registers
- `JobScheduler.cs`: how jobs are timed
- `BookingExpiryJob.cs`: a small example job
