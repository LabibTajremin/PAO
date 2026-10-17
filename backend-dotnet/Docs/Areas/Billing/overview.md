# Billing area — overview

Cash on delivery and merchant dues (ADR-0035): the commission ledger, the due limit on accept, merchant payment submissions and admin review. Its schema and operations arrive in P17 task 5.

Code: `PAO.Core/Areas/Billing/`; contracts: `PAO.Lib/Areas/Billing/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IBillingSharedService` | The only way other areas reach Billing (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetDueStatus` | Returns the merchant's due against the block limit; Booking checks it before an accept (ADR-0035 §3). |
| `RecordCommission` | Debits PAO's commission on a completed job to the merchant's ledger (ADR-0035 §2); idempotent per booking. |
