# Identity area — data

Schema `identity`, created by the scripts in `DB Changes/identity/` ([database index](../../Database/README.md)).

| Table | Created by |
|---|---|
| `identity.accounts` | `DB Changes/identity/0001_init.sql` |
| `identity.roles` | `DB Changes/identity/0001_init.sql` |
| `identity.account_roles` | `DB Changes/identity/0001_init.sql` |
| `identity.admin_credentials` | `DB Changes/identity/0001_init.sql` |
| `identity.blocked_phones` | `DB Changes/identity/0001_init.sql` |
| `identity.permissions` | `DB Changes/identity/0001_init.sql` |
| `identity.role_permissions` | `DB Changes/identity/0001_init.sql` |
| `identity.screens` | `DB Changes/identity/0001_init.sql` |
| `identity.role_screens` | `DB Changes/identity/0001_init.sql` |
| `identity.outbox` | `DB Changes/identity/0001_init.sql` |
| `identity.processed_events` | `DB Changes/identity/0001_init.sql` |

EF models: `PAO.EF/Identity/` (`Account`, `AccountRole`, `AdminCredentials`, `BlockedPhone`
and the RBAC tables).

| Repository | Store |
|---|---|
| `IIdentityRepository` | The contract: reads, writes and `Publish` to `identity.outbox`. |
| `IdentityRepository` | Reads with EF projections (roles in the same query, grants in one query per table). |
| `IdentityRepository.Writes` | Writes as SQL joining the command's transaction; TOTP secrets encrypted with the data key. |
| `RedisCodeStores` | `RedisCodeStore` (`otp:{purpose}:{phone}` hash) and `RedisSendThrottle` (`rl:otp:resend|phone|ip:*`). |
| `RedisSessionStores` | `RedisSessionStore` (`rt:{familyId}` hash, `sess:{accountId}` set) and `RedisChallengeStore` (`mfa:{id}` JSON). |

Redis layouts are unchanged from earlier releases, so existing sessions stay valid.
