# Billing area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).
Errors map through `BillingErrorMap`: `billing.not_found` → 404 `NOT_FOUND`,
`billing.not_pending` → 409 `PAYMENT_NOT_PENDING`. The due limit on accept is answered by
Booking's map: `billing.due_limit` → 409 `MERCHANT_DUE_LIMIT` on
`POST /v1/provider/jobs/{bookingId}/accept`.

| Controller | Operations | Attribute |
|---|---|---|
| `BillingControllers` | the file holding the error map and the two controllers below | |
| `ProviderBillingController` | `GET /v1/provider/billing/summary` (getMyDue), `GET /v1/provider/billing/ledger` (listMyLedger), `GET /v1/provider/billing/payments` (listMyPayments), `POST /v1/provider/billing/payments` (submitPayment, 201) | `[Merchant(Permission = "provider:manage:own")]` |
| `AdminBillingController` | `GET /v1/admin/billing/payments?status=` (listPaymentSubmissions), `POST /v1/admin/billing/payments/{submissionId}/confirm` (confirmPayment), `POST /v1/admin/billing/payments/{submissionId}/reject` (rejectPayment), `GET /v1/admin/billing/merchants/{providerId}/ledger` (getMerchantLedger) | `[Admin(Permission = "billing:manage")]` |

`billing:manage` is granted to `support_agent` and `super_admin` by
`DB Changes/identity/0003_billing_permission.sql`.
