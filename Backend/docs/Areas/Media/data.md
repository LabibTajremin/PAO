# Media area — data

Schema `media`, created by the scripts in `database/changes/media/` ([database index](../../Database/README.md)).

| Table | Created by |
|---|---|
| `media.objects` | `database/changes/media/0001_init.sql` |
| `media.outbox` | `database/changes/media/0001_init.sql` |
| `media.processed_events` | `database/changes/media/0001_init.sql` |

## Repositories

| Repository | Role |
|---|---|
| `MediaRepository` | `media.objects`: create pending, get, confirm, attach, orphans (500 per run), by owner, and batch deletes (one statement). |

Db model: `src/PAO.EF/Media/MediaObjectRecord`. Files live in the private bucket (`S3_BUCKET_PRIVATE`) under `{purpose}/{owner}/{id}`.
