# Admin area — overview

Platform settings (A-10), complaints and reports (C-14, A-07), the dashboard (A-09) and the
provider and customer console with bans and suspensions (A-05). Admin users and roles belong
to Identity; verification documents to Verification; the bookings monitor to Booking (ADR-0026).

Code: `PAO.Core/Areas/Admin/`; contracts: `PAO.Lib/Areas/Admin/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IAdminSharedService` | The only way other areas reach Admin (`Services/Shared/`). |
| `AdminSharedService` | Its implementation: Booking, Customer, Merchant and Verification read the typed settings here. |
| `AdminRules` | setting types (Go's parsing rules), report and resolution rules, the 30-day dashboard window |
| `SettingValues` | values by key cached in Redis under `cache:settings` (10 minutes, dropped on update), typed with defaults for damaged rows |
| `ComplaintSteps` | the resolved check and cursor pages shared by the queue and the console |
| `AdminPeers` | Merchant, Customer, Verification, Booking, Rating, Identity, Audit, Catalog and Media, resolved on first use; booking parties, complaint photos, who may work complaints |
| `AdminConsole` | provider and customer rows and detail pages, status changes through Identity |
| `AdminStatsSubscriptions` | the dashboard read model (see [events](events.md)) |

## Shared contract

| Method | Contract |
|---|---|
| `GetSettings` | Returns the typed platform settings (A-10), defaults filled in. |
| `CountVerifiedComplaints` | Returns verified complaints against a person; they feed the merchant quality review (PRD §6.4). |

Mapping: `AdminMappingProfile`.
