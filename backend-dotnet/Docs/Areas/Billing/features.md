# Billing area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Commission` | `ChargeCommission` | command | sent for `booking.BookingCompleted`; one debit per booking (`ON CONFLICT DO NOTHING`), so redelivery charges and notifies once; publishes `billing.CommissionCharged` when the amount is above zero |
| `Ledger` | `GetDue`, `ListLedger` | query | the partner app's due banner and ledger, newest first |
| `Ledger` | `GetMerchantLedger` | query | the admin console's view of one merchant: summary and first ledger page |
| `Payments` | `SubmitPayment` | command | amount > 0, method `cash_to_agent`/`bkash`/`nagad`/`bank`, reference 1–120 characters; `billing.PaymentSubmitted` |
| `Payments` | `ConfirmPayment` | command | pending only (`PAYMENT_NOT_PENDING` otherwise, `NOT_FOUND` when unknown); credits the ledger, which can lift the block; `billing.PaymentConfirmed` |
| `Payments` | `RejectPayment` | command | pending only; reason of 3–500 characters required; `billing.PaymentRejected` |
| `Payments` | `ListPayments` | query | one merchant's submissions, or the admin queue filtered by status |
