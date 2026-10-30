# Verification area — data

Schema `verification`, created by the scripts in `DB Changes/verification/` ([database index](../../Database/README.md)).

| Table | Created by |
|---|---|
| `verification.items` | `DB Changes/verification/0001_init.sql` |
| `verification.documents` | `DB Changes/verification/0001_init.sql` |
| `verification.nid_records` | `DB Changes/verification/0001_init.sql` |
| `verification.blocked_nids` | `DB Changes/verification/0001_init.sql` |
| `verification.levels` | `DB Changes/verification/0001_init.sql` |
| `verification.level2_sessions` | `DB Changes/verification/0001_init.sql` |
| `verification.reminders_sent` | `DB Changes/verification/0001_init.sql` |
| `verification.outbox` | `DB Changes/verification/0001_init.sql` |
| `verification.processed_events` | `DB Changes/verification/0001_init.sql` |
| `verification.closed_accounts` | `DB Changes/verification/0002_closures.sql` |

## Repositories

| Repository | Role |
|---|---|
| `VerificationStateRepository` | Loads whole merchant states (one query per table for any number of merchants), locks `levels` rows `FOR UPDATE`, saves with one `SaveChanges` and writes events to `verification.outbox` with one `unnest` insert. |
| `VerificationRepository` | Levels, pending count, the review queue, sessions, expiry queries, reminders (one insert per threshold), the NID block list and blocking. |
| `ClosedAccountRepository` | `closed_accounts`, Level 2 photos of closed accounts and the batch purge of every verification table. |

NID numbers are `nonce ‖ ciphertext ‖ tag` (AES-GCM, `DataCipher`), the layout already stored.
