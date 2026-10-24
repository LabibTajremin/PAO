/// API replies shared by the bookings and report tests.
const bookingId = '11111111-1111-1111-1111-111111111111';

/// A service name in both languages.
Map<String, Object?> named(String en, [String bn = 'ফ্যান মেরামত']) => {
  'en': en,
  'bn': bn,
};

/// One row of `GET /v1/customer/bookings`.
Map<String, Object?> summary({
  String id = bookingId,
  String status = 'accepted',
  String service = 'Fan repair',
  String? provider = 'Rahim Uddin',
}) => {
  'id': id,
  'number': 'PAO-104233',
  'status': status,
  'serviceName': named(service),
  'counterpartName': ?provider,
  'total': 113000,
  'createdAt': '2026-10-09T04:00:00Z',
};

/// One priced line.
Map<String, Object?> item(String name, {bool extra = false}) => {
  'subServiceId': '22222222-2222-2222-2222-222222222222',
  'priceVersionId': '33333333-3333-3333-3333-333333333333',
  'name': named(name),
  'unit': 'unit',
  'quantity': 2,
  'unitPrice': 50000,
  'total': 100000,
  'extra': extra,
};

/// A timeline step.
Map<String, Object?> step(
  String status, {
  String actor = 'system',
  String? reason,
}) => {
  'status': status,
  'at': '2026-10-09T04:00:00Z',
  'actor': actor,
  'reason': ?reason,
};

/// `GET /v1/customer/bookings/{id}`.
Map<String, Object?> booking({
  String status = 'accepted',
  Map<String, Object?>? provider = const {},
  List<Map<String, Object?>>? timeline,
  bool? reviewed,
  String? note,
}) => {
  'id': bookingId,
  'number': 'PAO-104233',
  'status': status,
  'serviceId': '44444444-4444-4444-4444-444444444444',
  'serviceName': named('Fan repair'),
  'provider': ?(provider == null
      ? null
      : {
          'id': '55555555-5555-5555-5555-555555555555',
          'name': 'Rahim Uddin',
          'phone': '+8801711111111',
          'rating': 4.8,
          'ratingCount': 132,
          ...provider,
        }),
  'items': [item('Ceiling fan'), item('Regulator', extra: true)],
  'total': 200000,
  'timing': 'asap',
  'address': {'area': 'Banani', 'line1': 'House 12, Road 5'},
  'note': ?note,
  'paymentMethod': 'cash',
  'reviewedByMe': ?reviewed,
  'createdAt': '2026-10-09T04:00:00Z',
  'timeline': timeline ?? [step('requested'), step(status)],
};

/// `GET /v1/customer/bookings/{id}/receipt`.
Map<String, Object?> receipt({String? area = 'Banani'}) => {
  'bookingId': bookingId,
  'number': 'PAO-104233',
  'completedAt': '2026-10-09T06:30:00Z',
  'serviceName': named('Fan repair'),
  'providerName': 'Rahim Uddin',
  'customerName': 'Nusrat Jahan',
  'area': ?area,
  'items': [item('Ceiling fan'), item('Regulator', extra: true)],
  'total': 200050,
  'paymentMethod': 'cash',
};
