# Merchant area — overview

Merchant (provider) profiles, the enrolment wizard, services offered, presence and nearby search. "Merchant" is the owner's name for the provider role; the schema, events and API paths keep `provider`.

Code: `PAO.Core/Areas/Merchant/`; contracts: `PAO.Lib/Areas/Merchant/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IMerchantSharedService` | The only way other areas reach Merchant (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetMerchant` | Returns a merchant's profile, or throws `provider.not_found`. |
| `IsAvailable` | Reports whether the merchant is online right now. |
| `FindNearby` | Returns verified, online merchants registered for the service within its radius: Level 2 first, then by the requested sort (PRD §5, D11). |
| `Enrolment` | Returns the wizard progress; a merchant who has saved nothing yet has every step open. |
| `MarkStepDone` | Records a document step saved by Verification. |
| `MarkSubmitted` | Records that the merchant sent the enrolment for review. |
| `ForceOffline` | Removes the merchant from presence, e.g. after a ban or an expired document. |
| `SearchMerchants` | Lists merchants for the admin console, newest first (A-05). |
