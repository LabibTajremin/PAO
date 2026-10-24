import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// API replies shared by the jobs and earnings tests.
const bookingId = '11111111-1111-1111-1111-111111111111';

/// A service name in both languages.
Map<String, Object?> named(String en, [String bn = 'নাম']) => {
  'en': en,
  'bn': bn,
};

/// One row of `GET /v1/provider/jobs`.
Map<String, Object?> summary({
  String id = bookingId,
  String status = 'accepted',
  String service = 'Fan repair',
  String? customer = 'Nusrat Jahan',
}) => {
  'id': id,
  'number': 'PAO-104233',
  'status': status,
  'serviceName': named(service),
  'counterpartName': ?customer,
  'total': 113000,
  'createdAt': '2026-10-09T04:00:00Z',
};

/// An API error body.
Map<String, Object?> apiError(String code) => {
  'error': {'code': code, 'message': 'x'},
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

/// `GET /v1/provider/jobs/{id}`.
Map<String, Object?> booking({
  String status = 'accepted',
  bool customer = true,
}) => {
  'id': bookingId,
  'number': 'PAO-104233',
  'status': status,
  'serviceId': '44444444-4444-4444-4444-444444444444',
  'serviceName': named('Fan repair'),
  'items': [item('Ceiling fan'), item('Regulator', extra: true)],
  'total': 113000,
  'timing': 'scheduled',
  'scheduledAt': '2026-10-10T05:00:00Z',
  'address': {'area': 'Banani'},
  'createdAt': '2026-10-09T04:00:00Z',
  'paymentMethod': 'cash',
  'customer': ?(customer
      ? {'id': '55555555-5555-5555-5555-555555555555', 'name': 'Nusrat Jahan'}
      : null),
  'timeline': [
    {'status': 'requested', 'at': '2026-10-09T04:00:00Z', 'actor': 'customer'},
    {'status': status, 'at': '2026-10-09T04:01:00Z', 'actor': 'provider'},
  ],
};

/// `GET /v1/provider/jobs/{id}/receipt`.
Map<String, Object?> receipt() => {
  'bookingId': bookingId,
  'number': 'PAO-104233',
  'completedAt': '2026-10-09T08:00:00Z',
  'serviceName': named('Fan repair'),
  'providerName': 'Rahim Uddin',
  'customerName': 'Nusrat',
  'items': [item('Ceiling fan')],
  'total': 100000,
  'paymentMethod': 'cash',
};

/// `POST /v1/provider/jobs/{id}/reports`.
Map<String, Object?> complaint() => {
  'id': '66666666-6666-6666-6666-666666666666',
  'ticketNumber': 'TCK-002341',
  'bookingId': bookingId,
  'reporterRole': 'provider',
  'reporterId': '77777777-7777-7777-7777-777777777777',
  'reason': 'payment',
  'description': 'The customer refused to pay.',
  'status': 'open',
  'createdAt': '2026-10-09T08:00:00Z',
};

/// A 1×1 PNG, small enough to inline and real enough to compress.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGA'
  'WjR9awAAAABJRU5ErkJggg==',
);

/// Gives the test a phone-width screen tall enough that whole pages build.
void tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(400, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
