# Jobs

Every `IScheduledJob`, its schedule and effect. Areas add theirs as they are ported
(02-architecture §9). Back to [Operations](README.md).

| Job class | Name | Schedule | Effect |
|---|---|---|---|
| `MediaOrphanPurgeJob` | `media.purge_orphans` | daily 03:30 Asia/Dhaka | deletes uploads never attached to a record within 24 hours (500 per run) |
| `MerchantPresenceReapJob` | `provider.reap_lost_presence` | every minute | merchants whose 90 s heartbeat lapsed go offline with `ProviderWentOffline{reason: heartbeat_lost}` |
| `MediatorJob` | — | base class | runs one mediator request in a fresh scope; the three verification jobs below use it |
| `ExpireDocumentsJob` | `verification.expire_documents` | daily 02:00 Asia/Dhaka | expires approved documents past their date; levels drop |
| `ExpiryRemindersJob` | `verification.expiry_reminders` | daily 09:00 Asia/Dhaka | 30, 7 and 1 day reminders, each once |
| `PurgeClosedAccountsJob` | `verification.purge_closed` | daily 03:45 Asia/Dhaka | purges closed accounts after the retention period (ADR-0023), 500 per run |
| `OutboxPurgeJob` | `outbox.purge_published` | daily 03:00 Asia/Dhaka | deletes outbox events delivered more than `Jobs:OutboxRetentionDays` (7) ago |

The outbox relay is not a job: `WorkerLoop` runs it every `Jobs:OutboxRelayIntervalMs` (250 ms).
