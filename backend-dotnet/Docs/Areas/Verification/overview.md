# Verification area — overview

Verification items and documents, NID records, levels, Level 2 sessions, expiry and reminders, and the purge of closed accounts' documents.

Code: `PAO.Core/Areas/Verification/`; contracts: `PAO.Lib/Areas/Verification/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IVerificationSharedService` | The only way other areas reach Verification (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetLevel` | Returns the merchant's verification level (0 when never verified). |
| `GetLevels` | Returns levels for many merchants at once, keyed by merchant id, for search ranking (one query, no N+1). |
| `CanReceiveBookings` | Reports whether the merchant may receive bookings for the service: Level at least the service's required level (Level 2 when flagged), no expired document and not blocked (PRD §6.1, §6.4). A null service checks any service. |
| `GetItems` | Returns the merchant's verification items sorted by type (A-05). |
| `CountPendingReviews` | Counts submitted merchants with an item awaiting review (A-09). |
