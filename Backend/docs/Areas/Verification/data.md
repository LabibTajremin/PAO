# Verification area — data

Schema `verification`, created by the scripts in `database/changes/verification/` ([database index](../../Database/README.md)).

| Table | Created by |
|---|---|
| `verification.items` | `database/changes/verification/0001_init.sql` |
| `verification.documents` | `database/changes/verification/0001_init.sql` |
| `verification.nid_records` | `database/changes/verification/0001_init.sql` |
| `verification.blocked_nids` | `database/changes/verification/0001_init.sql` |
| `verification.levels` | `database/changes/verification/0001_init.sql` |
| `verification.level2_sessions` | `database/changes/verification/0001_init.sql` |
| `verification.reminders_sent` | `database/changes/verification/0001_init.sql` |
| `verification.outbox` | `database/changes/verification/0001_init.sql` |
| `verification.processed_events` | `database/changes/verification/0001_init.sql` |
| `verification.closed_accounts` | `database/changes/verification/0002_closures.sql` |

## Repositories

| Repository | Role |
|---|---|
| `VerificationStateRepository` | Loads whole merchant states (one query per table for any number of merchants), locks `levels` rows `FOR UPDATE`, saves with one `SaveChanges` and writes events to `verification.outbox` with one `unnest` insert. |
| `VerificationRepository` | Levels, pending count, the review queue, sessions, expiry queries, reminders (one insert per threshold), the NID block list and blocking. |
| `ClosedAccountRepository` | `closed_accounts`, Level 2 photos of closed accounts and the batch purge of every verification table. |

NID numbers are `nonce ‖ ciphertext ‖ tag` (AES-GCM, `DataCipher`), the layout already stored.
