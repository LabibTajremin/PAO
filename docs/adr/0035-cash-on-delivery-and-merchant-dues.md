# ADR-0035: Cash on delivery, merchant dues and two new service categories

- Status: Accepted
- Date: 2026-10-17
- Source: owner decisions, 2026-10-16/17 (handwritten notes p.5 and follow-up answers);
  answers the PRD open question on the revenue model and on how providers pay commission
  from cash jobs.

## Decision

1. **Payment.** Cash on delivery is the only payment method in the first release. Every
   booking records `payment_method = cash_on_delivery`; the customer app shows it on the
   booking summary and the final bill. Digital payment stays Phase 2.
2. **Commission.** When a job completes, PAO's commission becomes a debit on the merchant's
   ledger. The rate is the admin setting `billing.commission_rate_bp` in basis points;
   the default is 1000 (10% of the final job price). Amounts are paisa (E9), rounded half
   up.
3. **Due limit.** A merchant's due is the sum of unpaid debits. The merchant cannot accept
   a new job while the due is above the admin setting `billing.due_block_amount`. The
   default is 50000 paisa (৳500); the owner may change it. Accepting returns
   `409 MERCHANT_DUE_LIMIT`. The merchant still receives every job offer and notification
   and sees the reason, the due and how to pay it. Jobs already accepted are unaffected.
4. **Clearing.** The merchant submits a payment in the partner app: amount, method (cash
   to agent, bKash, Nagad, bank) and a reference. An admin with `billing:manage` confirms
   or rejects it in the console. Confirming credits the ledger and can lift the block;
   rejecting needs a reason. Every step is audited and notifies the merchant.
5. **Catalog.** Two new categories are seeded with services and sub-services, English and
   Bangla names and fixed prices: **Catering** and **Monthly Bazar**. Admins edit them like
   any other category.

## Consequences

- A new **Billing** area owns the ledger, submissions and settings. Booking calls Billing's
  shared service when a job completes and before an accept; no other area writes the
  ledger.
- New API operations under `/v1/provider/billing/...` and `/v1/admin/billing/...` are added
  to `api/openapi.yaml`, and the error code `MERCHANT_DUE_LIMIT` is added. Existing
  operations are unchanged, apart from the additive `paymentMethod` field on booking
  views.
- Partner app: due banner, ledger and pay screen. Admin console: payment queue and the two
  settings. Customer app: "Cash on delivery" on the booking summary.
