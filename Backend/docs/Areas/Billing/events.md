# Billing area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)). The aggregate is the
merchant, so a merchant's events arrive in order.

| Published event | Fields |
|---|---|
| `billing.CommissionCharged` | `providerId`, `bookingId`, `amountPaisa`, `duePaisa`, `blocked` |
| `billing.PaymentSubmitted` | `submissionId`, `providerId`, `amountPaisa`, `method`, `duePaisa`, `reason`, `actorId` |
| `billing.PaymentConfirmed` | as above; `actorId` is the admin |
| `billing.PaymentRejected` | as above, with the `reason` |

Every event is audited (`billing.commission_charged`, `billing.payment_submitted`,
`billing.payment_confirmed`, `billing.payment_rejected`) and notifies the merchant in the
partner app (`commission_charged`, or `due_limit_reached` when the commission crossed the
limit; `payment_submitted`, `payment_confirmed`, `payment_rejected`).

Consumed by `BillingSubscriptions` (handler `billing`): `booking.BookingCompleted`
(`bookingId`, `providerId`, `number`, `totalPaisa`) charges the commission.
