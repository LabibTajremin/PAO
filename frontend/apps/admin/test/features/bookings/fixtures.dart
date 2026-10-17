import '../providers/fixtures.dart';

/// One priced line.
Map<String, Object?> item(String name, {bool extra = false}) => {
  'subServiceId': '99999999-9999-9999-9999-999999999999',
  'priceVersionId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'name': named(name),
  'unit': 'unit',
  'quantity': 2,
  'unitPrice': 50000,
  'total': 100000,
  'extra': extra,
};

Map<String, Object?> _step(String status, String at, String actor) => {
  'status': status,
  'at': at,
  'actor': actor,
};

/// `GET /v1/admin/bookings/{id}`: a completed booking with everything, or a
/// cancelled ASAP one with no provider.
Map<String, Object?> booking({bool cancelled = false}) => {
  'id': bookingId,
  'number': 'PAO-104233',
  'status': cancelled ? 'cancelled' : 'completed',
  'serviceId': '44444444-4444-4444-4444-444444444444',
  'serviceName': named('Fan repair'),
  'items': [item('Ceiling fan'), item('Regulator', extra: true)],
  'total': 113000,
  'timing': cancelled ? 'asap' : 'scheduled',
  if (!cancelled) ...{
    'scheduledAt': '2026-10-10T05:00:00Z',
    'endsAt': '2026-10-10T09:00:00Z',
    'note': 'Gate code 1234',
    'cashReceived': true,
    'provider': {
      'id': providerId,
      'name': 'Rahim Uddin',
      'phone': '+8801712345678',
    },
    'pendingExtras': {
      'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'items': [item('Capacitor', extra: true)],
      'addedTotal': 13000,
      'newTotal': 113000,
      'status': 'approved',
      'proposedAt': '2026-10-10T06:00:00Z',
    },
  },
  'customer': {'id': customerId, 'name': 'Nusrat Jahan'},
  'address': cancelled
      ? {'area': 'Banani'}
      : {'area': 'Banani', 'line1': 'House 12, Road 5', 'line2': 'Flat 3B'},
  'createdAt': '2026-10-09T04:00:00Z',
  'paymentMethod': 'cash',
  'timeline': [
    _step('requested', '2026-10-09T04:00:00Z', 'customer'),
    if (cancelled)
      {
        ..._step('cancelled', '2026-10-09T04:05:00Z', 'customer'),
        'reason': 'changed_mind',
      }
    else ...[
      _step('accepted', '2026-10-09T04:01:00Z', 'provider'),
      _step('in_progress', '2026-10-10T05:10:00Z', 'provider'),
      _step('completed', '2026-10-10T08:00:00Z', 'system'),
    ],
  ],
};

/// The same booking with the extras in another state and an admin step.
Map<String, Object?> bookingWithExtras(String status) {
  final b = booking();
  (b['pendingExtras']! as Map<String, Object?>)['status'] = status;
  (b['timeline']! as List<Object?>).add(
    _step('cancelled', '2026-10-10T09:00:00Z', 'admin'),
  );
  return b;
}
