// JSON shapes from api/schemas shared by the booking, live, cancel and rating
// tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';

import '../../support/harness.dart';

/// A service name in both languages.
const fanRepair = {'en': 'Fan repair', 'bn': 'ফ্যান মেরামত'};

/// API path of booking b1.
const bookingPath = '/v1/customer/bookings/b1';

/// A sub-service of `s1`.
Map<String, Object?> subService(
  String id, {
  int price = 50000,
  bool published = true,
}) => {
  'id': id,
  'serviceId': 's1',
  'name': {'en': 'Item $id', 'bn': 'আইটেম $id'},
  'unit': 'unit',
  'price': price,
  'priceVersionId': 'pv-$id',
  'published': published,
};

/// Service `s1` with three sub-services, one unpublished.
Map<String, Object?> service({String model = 'on_demand'}) => {
  'id': 's1',
  'categoryId': 'k1',
  'name': fanRepair,
  'iconKey': 'fan',
  'serviceModel': model,
  'requiredLevel': 1,
  'searchRadiusM': 5000,
  'womenProvidersOnly': false,
  'requiresLevel2': false,
  'published': true,
  'subServices': [
    subService('x1'),
    subService('x2', price: 30000),
    subService('x3', published: false),
  ],
};

/// Provider p1's public profile.
const Map<String, Object?> providerProfile = {
  'id': 'p1',
  'name': 'Rahim Uddin',
  'badge': 'verified_pro',
  'level': 2,
  'bio': 'Electrician',
  'experienceYears': 8,
  'services': <Object>[],
  'rating': {
    'average': 4.8,
    'count': 132,
    'distribution': {'5': 132},
  },
  'completedJobs': 210,
  'memberSince': '2025-01-01T00:00:00Z',
};

/// A saved address.
Map<String, Object?> address(
  String id, {
  String label = 'home',
  bool isDefault = false,
}) => {
  'id': id,
  'label': label,
  'line1': 'House $id, Road 5',
  'area': 'Banani',
  'location': {'lat': 23.79, 'lng': 90.4},
  'isDefault': isDefault,
};

/// One booked line.
Map<String, Object?> line({
  String id = 'x1',
  int quantity = 1,
  int unitPrice = 50000,
  bool extra = false,
}) => {
  'subServiceId': id,
  'priceVersionId': 'pv-$id',
  'name': {'en': 'Item $id', 'bn': 'আইটেম $id'},
  'unit': 'unit',
  'quantity': quantity,
  'unitPrice': unitPrice,
  'total': unitPrice * quantity,
  'extra': extra,
};

/// The provider on a booking; the phone only after acceptance.
Map<String, Object?> party({String? phone = '01711111111'}) => {
  'id': 'p1',
  'name': 'Rahim Uddin',
  'phone': ?phone,
  'badge': 'verified',
  'rating': 4.8,
  'ratingCount': 132,
};

/// Booking b1 as the customer sees it.
Map<String, Object?> booking({
  String status = 'accepted',
  String timing = 'asap',
  String? scheduledAt,
  String? deadline,
  Map<String, Object?>? provider,
  Map<String, Object?>? pendingExtras,
  bool? reviewedByMe,
  bool? cashReceived,
  String model = 'on_demand',
}) => {
  'id': 'b1',
  'number': 'PAO-104233',
  'status': status,
  'serviceId': 's1',
  'serviceName': fanRepair,
  'serviceModel': model,
  'provider': provider ?? party(),
  'items': [line(quantity: 2), line(id: 'x2', unitPrice: 30000, extra: true)],
  'total': 130000,
  'timing': timing,
  'scheduledAt': ?scheduledAt,
  'address': {'area': 'Banani', 'line1': 'House 12, Road 5'},
  'acceptDeadline': ?deadline,
  'pendingExtras': ?pendingExtras,
  'reviewedByMe': ?reviewedByMe,
  'cashReceived': ?cashReceived,
  'paymentMethod': 'cash',
  'createdAt': '2026-10-09T03:58:00Z',
  'timeline': <Object>[],
};

/// An extras proposal in [status].
Map<String, Object?> proposal({String status = 'pending', String id = 'p1'}) =>
    {
      'id': id,
      'items': [line(id: 'x3', extra: true)],
      'addedTotal': 50000,
      'newTotal': 180000,
      'status': status,
      'proposedAt': '2026-10-09T04:00:00Z',
    };

/// Opens [part] of booking b1 with [json] as the API's answer.
Future<Harness> openBooking(
  WidgetTester tester,
  Map<String, Object?> json,
  String part,
) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http.onGet(bookingPath, (s) => s.reply(200, json));
  await h.pumpApp(tester, Routes.booking('b1', part));
  return h;
}
