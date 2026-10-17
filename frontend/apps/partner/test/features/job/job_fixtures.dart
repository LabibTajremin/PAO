// JSON shapes from api/schemas/booking.yaml shared by the job, request and
// home tests.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';

import '../../support/harness.dart';

/// A phone-height screen, so whole job screens are built without scrolling.
void tallScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A service name in both languages.
const fanRepair = {'en': 'Fan repair', 'bn': 'ফ্যান মেরামত'};

/// The API error body for [code].
Map<String, Object?> apiError(String code) => {
  'error': {'code': code, 'message': 'x'},
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
  'name': {'en': 'Ceiling fan', 'bn': 'সিলিং ফ্যান'},
  'unit': 'unit',
  'quantity': quantity,
  'unitPrice': unitPrice,
  'total': unitPrice * quantity,
  'extra': extra,
};

/// The customer once the booking is accepted.
const customer = {'id': 'c1', 'name': 'Nusrat Jahan', 'phone': '01711111111'};

/// A booking as the provider sees it.
Map<String, Object?> booking({
  String status = 'accepted',
  String? deadline,
  Map<String, Object?>? party = customer,
  Map<String, Object?>? pendingExtras,
  List<Map<String, Object?>> timeline = const [],
  bool? reviewedByMe,
  String timing = 'asap',
  String? scheduledAt,
  String? note,
  int? distanceM,
  bool located = true,
}) => {
  'id': 'b1',
  'number': 'PAO-104233',
  'status': status,
  'serviceId': 's1',
  'serviceName': fanRepair,
  'customer': ?party,
  'items': [line(), line(id: 'x2', unitPrice: 30000, extra: true)],
  'total': 80000,
  'timing': timing,
  'scheduledAt': ?scheduledAt,
  'address': {
    'area': 'Banani',
    if (located) 'line1': 'House 12, Road 5',
    if (located) 'location': {'lat': 23.79, 'lng': 90.4},
    'distanceM': ?distanceM,
  },
  'note': ?note,
  'acceptDeadline': ?deadline,
  'pendingExtras': ?pendingExtras,
  'reviewedByMe': ?reviewedByMe,
  'paymentMethod': 'cash',
  'createdAt': '2026-10-09T03:50:00Z',
  'timeline': timeline,
};

/// An extras proposal in [status].
Map<String, Object?> proposal(String status) => {
  'id': 'p1',
  'items': [line(extra: true)],
  'addedTotal': 50000,
  'newTotal': 130000,
  'status': status,
  'proposedAt': '2026-10-09T04:00:00Z',
};

/// One row of a job list.
Map<String, Object?> summary({String id = 'b1', String status = 'requested'}) =>
    {
      'id': id,
      'number': 'PAO-$id',
      'status': status,
      'serviceName': fanRepair,
      'counterpartName': 'Nusrat',
      'total': 80000,
      'createdAt': '2026-10-09T03:50:00Z',
    };

/// A catalog with service `s1` holding [subServices].
Map<String, Object?> catalog(List<Map<String, Object?>> subServices) => {
  'version': 7,
  'categories': [
    {
      'id': 'k1',
      'name': {'en': 'Home', 'bn': 'বাড়ি'},
      'iconKey': 'home',
      'sortOrder': 1,
      'published': true,
      'services': [_service('s0', const []), _service('s1', subServices)],
    },
  ],
};

/// A sub-service of `s1`.
Map<String, Object?> subService(
  String id, {
  int price = 50000,
  bool published = true,
}) => {
  'id': id,
  'serviceId': 's1',
  'name': {'en': 'Capacitor $id', 'bn': 'ক্যাপাসিটর $id'},
  'unit': 'unit',
  'price': price,
  'priceVersionId': 'pv-$id',
  'maxQuantity': 3,
  'published': published,
};

Map<String, Object?> _service(String id, List<Map<String, Object?>> subs) => {
  'id': id,
  'categoryId': 'k1',
  'name': fanRepair,
  'iconKey': 'fan',
  'serviceModel': 'on_demand',
  'requiredLevel': 1,
  'searchRadiusM': 5000,
  'womenProvidersOnly': false,
  'requiresLevel2': false,
  'published': true,
  'subServices': subs,
};

/// Opens [part] of booking b1 with [job] as the API's answer.
Future<Harness> openJob(
  WidgetTester tester,
  Map<String, Object?> job, [
  String part = 'live',
]) async {
  tallScreen(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http.onGet('/v1/provider/jobs/b1', (s) => s.reply(200, job));
  await h.pumpApp(tester, Routes.job('b1', part));
  return h;
}
