# Jobs

Every `IScheduledJob`, its schedule and effect. Areas add theirs as they are ported
(02-architecture §9). Back to [Operations](README.md).

| Job class | Name | Schedule | Effect |
|---|---|---|---|
| `OutboxPurgeJob` | `outbox.purge_published` | daily 03:00 Asia/Dhaka | deletes outbox events delivered more than `Jobs:OutboxRetentionDays` (7) ago |

The outbox relay is not a job: `WorkerLoop` runs it every `Jobs:OutboxRelayIntervalMs` (250 ms).
