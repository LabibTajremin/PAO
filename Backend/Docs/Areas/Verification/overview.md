# Verification area — overview

Verification items and documents, NID records, levels, Level 2 sessions, expiry and reminders, and the purge of closed accounts' documents.

Code: `PAO.Core/Areas/Verification/`; contracts: `PAO.Lib/Areas/Verification/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IVerificationSharedService` | The only way other areas reach Verification (`Services/Shared/`). |
| `VerificationSharedService` | Implements it: level (used by Identity's getMyPermissions), levels, canReceiveBookings, items, pending count. |
| `VerificationRules` | Pure rules: item lifecycle, level, clearance expiry, NID format, Level 2 result and cooling-off. |
| `VerificationStates` | Changes states under the row lock and publishes `ProviderLevelChanged`. |
| `VerificationPeers` | Merchant, Media, Catalog and Admin shared services, resolved lazily on first use. |
| `DocumentSteps` | The document steps of the wizard. |
| `MerchantStatus` | Status screen, submission, re-review after a saved profile step. |
| `ReviewItems` | Queue rows, the review screen and decisions. |
| `Level2Sessions` | Scheduling and recording Level 2 sessions. |
| `DocumentLifecycle` | Expiry, reminders, blocking, closures and the retention purge. |
| `VerificationEventSubscriptions` | Subscribes to `provider.EnrolmentStepSaved`, `identity.AccountStatusChanged`, `identity.AccountDeleted`; also holds `DocumentExpiryHook`, the `/__test/verification/expire` hook. |

## Dhaka dates

`DhakaDates` (PAO.Lib) gives the Dhaka calendar date, the 18th birthday (29 February rolls to
1 March as JavaScript did) and `IsAdult`, for the Merchant personal step.

## Shared contract

`IVerificationSharedService`; jobs in [jobs](../../Operations/jobs.md).
