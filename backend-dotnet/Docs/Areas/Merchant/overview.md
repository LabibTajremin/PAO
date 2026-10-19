# Merchant area — overview

Merchant (provider) profiles, the enrolment wizard, services offered, presence and nearby search. "Merchant" is the owner's name for the provider role; the schema, events and API paths keep `provider`.

Code: `PAO.Core/Areas/Merchant/`; contracts: `PAO.Lib/Areas/Merchant/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IMerchantSharedService` | The only way other areas reach Merchant (`Services/Shared/`). |
| `MerchantSharedService` | Its implementation. |
| `MerchantProfiles` | loads (creating an empty profile on first use) and saves, with `EnrolmentStepSaved` for profile steps |
| `MerchantEnrolment` | the wizard steps, emergency-contact codes through Identity, step marks and submission |
| `EnrolmentRules` | step order and progress, the 18th birthday in Dhaka, services, area and contact rules |
| `MerchantRules` | who may go online, badges, ranking and the women-only and working-radius filters |
| `MerchantPresence` | online, heartbeat, offline |
| `MerchantFinder` | nearby search (Redis GEO + one candidate query) and the admin list with live online flags |
| `MerchantViewsBuilder` | own profile (M28) and public profile (C11) |
| `MerchantReadModel` | level, status, rating, job and cancellation copies; quality flags (D13) |
| `MerchantSubscriptions` | event subscribers (see [events](events.md)) |
| `MerchantPeers` | Catalog, Identity, Media, Admin and Rating contracts, resolved on first use |

Verification's level reaches Merchant only through `verification.ProviderLevelChanged`; Identity's
`getMyPermissions` reads it through `IVerificationSharedService`, resolved lazily.

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

Mapping: `MerchantMappingProfile`. Job: `MerchantPresenceReapJob` ([jobs](../../Operations/jobs.md)).
