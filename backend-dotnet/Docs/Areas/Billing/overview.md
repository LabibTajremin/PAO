# Billing area — overview

Cash on delivery and merchant dues (ADR-0035): PAO's commission on every completed job is a
debit on the merchant's ledger, the merchant cannot accept new jobs while the due is above the
block limit, and the merchant clears the due by reporting payments that an admin confirms or
rejects.

Code: `PAO.Core/Areas/Billing/`; contracts: `PAO.Lib/Areas/Billing/`. Back to the [area index](../README.md).

## The due, precisely

- **Debit:** one `commission` ledger entry per completed booking, amount
  `round_half_up(final price × billing.commission_rate_bp / 10000)` in paisa, at the rate in
  force when the job completed (kept on the entry as `rate_bp`).
- **Credit:** one `payment` ledger entry per **confirmed** submission, for the submitted
  amount. Pending and rejected submissions never touch the ledger; the summary shows the
  pending total separately (`pendingPayments`).
- **Due** = Σ commission debits − Σ payment credits, floored at 0 (an overpayment is kept
  in the ledger and absorbs later commissions, but the due never shows as negative).
- **Blocked** = due **>** `billing.due_block_amount`. A due equal to the limit still accepts.
  Only accepting is refused (`409 MERCHANT_DUE_LIMIT`); offers, notifications and jobs
  already accepted are unaffected.

Both settings are admin settings (A-10): `billing.commission_rate_bp` (default 1000 = 10%,
clamped to 0–10000 when read) and `billing.due_block_amount` (default 50000 paisa = ৳500).

## Services

| Service | Role |
|---|---|
| `IBillingSharedService` | The only way other areas reach Billing (`Services/Shared/`). |
| `BillingSharedService` | Its implementation; Booking calls `GetDueStatus` before an accept through `BookingPeers.EnsureCanAccept`. |
| `BillingAccounts` | the due judged by the current settings (Admin's shared service), and keyset paging of ledgers and submissions |
| `BillingRules` | the half-up commission and the payment methods |
| `PaymentSteps` | fills the event of each submission step |
| `BillingSubscriptions` | charges the commission on `booking.BookingCompleted` (see [events](events.md)) |

## Shared contract

| Method | Contract |
|---|---|
| `GetDueStatus` | Returns the merchant's due against the block limit; Booking checks it before an accept (ADR-0035 §3). |
| `RecordCommission` | Debits PAO's commission on a completed job to the merchant's ledger (ADR-0035 §2); idempotent per booking. |

Mapping: `BillingMappingProfile` (with `DueTotals` and `DueWithLimits`, which hold the rules above).
