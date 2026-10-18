# Jobs

Every `IScheduledJob`, its schedule and effect. Areas add theirs as they are ported
(02-architecture §9). Back to [Operations](README.md).

| Job class | Name | Schedule | Effect |
|---|---|---|---|
| `MediaOrphanPurgeJob` | `media.purge_orphans` | daily 03:30 Asia/Dhaka | deletes uploads never attached to a record within 24 hours (500 per run) |
| `OutboxPurgeJob` | `outbox.purge_published` | daily 03:00 Asia/Dhaka | deletes outbox events delivered more than `Jobs:OutboxRetentionDays` (7) ago |

The outbox relay is not a job: `WorkerLoop` runs it every `Jobs:OutboxRelayIntervalMs` (250 ms).
