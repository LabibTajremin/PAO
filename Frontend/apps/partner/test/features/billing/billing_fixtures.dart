/// The provider's due summary endpoint.
const dueUrl = '/v1/provider/billing/summary';

/// The provider's ledger endpoint.
const ledgerUrl = '/v1/provider/billing/ledger';

/// The provider's payments endpoint.
const paymentsUrl = '/v1/provider/billing/payments';

/// A due summary; the default is blocked at ৳620 against ৳500.
Map<String, Object?> due({
  int amount = 62000,
  int limit = 50000,
  bool? blocked,
  int pending = 0,
  int rate = 1000,
}) => {
  'due': amount,
  'blockAmount': limit,
  'blocked': blocked ?? amount > limit,
  'commissionRateBp': rate,
  'pendingPayments': pending,
};

/// One ledger entry.
Map<String, Object?> entry({bool commission = true, String number = 'PAO-1'}) =>
    {
      'id': 'e-$number',
      'kind': commission ? 'commission' : 'payment',
      'amount': commission ? 11300 : 20000,
      if (commission) 'bookingId': '11111111-1111-1111-1111-111111111111',
      if (commission) 'bookingNumber': number,
      if (commission) 'jobTotal': 113000,
      'createdAt': '2026-10-09T08:00:00Z',
    };

/// One reported payment.
Map<String, Object?> payment({
  String status = 'pending',
  String? reason,
  String reference = 'TX1',
}) => {
  'id': 'p-$reference',
  'providerId': '33333333-3333-3333-3333-333333333333',
  'amount': 20000,
  'method': 'bkash',
  'reference': reference,
  'status': status,
  'reason': ?reason,
  'createdAt': '2026-10-09T08:00:00Z',
};
