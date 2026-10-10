import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/location/presentation/address_page.dart';
import 'package:pao_customer/features/providers/presentation/provider_profile_page.dart';
import 'package:pao_customer/features/service/presentation/service_page.dart';

import '../../support/harness.dart';
import '../location/fixtures.dart';
import '../service/fixtures.dart';
import 'fixtures.dart';

const _nearby = '/v1/customer/providers/nearby';
const _addresses = '/v1/customer/addresses';

String _list([String items = '$fanId:2']) => Uri(
  path: Routes.providersOf(electricianId),
  queryParameters: {'service': electricianId, 'items': items},
).toString();

Future<Harness> _start(
  WidgetTester tester, {
  List<Map<String, Object?>>? addresses,
}) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(
      _addresses,
      (s) => s.reply(200, addressList(addresses ?? [address()])),
    )
    ..onGet(
      _nearby,
      (s) => s.replyCallback(
        200,
        (o) => o.queryParameters['cursor'] == null
            ? nearby([
                card(rahimId, 'Rahim Uddin'),
                card(
                  karimId,
                  'Karim Mia',
                  badge: 'verified_pro',
                  rating: 3.9,
                  distance: 800,
                ),
              ], next: 'c2')
            : nearby([
                card(
                  salmaId,
                  'Salma Akter',
                  badge: 'verified_pro',
                  rating: 4.5,
                ),
              ]),
      ),
    );
  return h;
}

Future<void> _sortFilter(
  WidgetTester tester,
  Harness h,
  List<String> taps,
) async {
  await tester.tap(find.text('Sort & filter'));
  await tester.pumpAndSettle();
  for (final label in taps) {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Apply'));
  await h.settle(tester);
}

void main() {
  testWidgets('nearby providers page, sort, filter and open a profile', (
    tester,
  ) async {
    final h = await _start(tester);
    await h.pumpApp(tester, _list());
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('210 jobs done · 1.2 km away'), findsOneWidget);
    expect(find.text('210 jobs done · 800 m away'), findsOneWidget);
    expect(find.text('৳1,000'), findsOneWidget);
    expect(h.sent.last.queryParameters, {
      'serviceId': electricianId,
      'subServiceId': fanId,
      'quantity': 2,
      'addressId': homeAddressId,
      'sort': 'distance',
      'limit': 20,
    });
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Salma Akter'), findsOneWidget);
    await _sortFilter(tester, h, ['Top rated', '4 stars and above']);
    expect(h.sent.last.queryParameters['sort'], 'rating');
    expect(find.text('Karim Mia'), findsNothing);
    await _sortFilter(tester, h, ['PAO Verified Pro']);
    expect(find.text('Salma Akter'), findsOneWidget);
    expect(find.text('Rahim Uddin'), findsNothing);
    await tester.tap(find.text('Sort & filter'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salma Akter'));
    await h.settle(tester);
    final page = tester.widget<ProviderProfilePage>(
      find.byType(ProviderProfilePage),
    );
    expect(page.providerId, salmaId);
    expect(page.query, {'service': electricianId, 'items': '$fanId:2'});
  });

  testWidgets('no providers, a failure, and several items', (tester) async {
    final h = await _start(tester);
    h.http.onGet(_nearby, (s) => s.reply(500, apiError('INTERNAL')));
    await h.pumpApp(tester, _list('$fanId:1,$switchId:1'));
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('৳1,000'), findsNothing);
    h.http.onGet(_nearby, (s) => s.reply(200, nearby([])));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('No providers nearby right now'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('No providers nearby right now'), findsOneWidget);
  });

  testWidgets('without an address the customer adds one first', (tester) async {
    final h = await _start(tester, addresses: []);
    await h.pumpApp(tester, _list());
    expect(find.text('Add your address first'), findsOneWidget);
    await tester.tap(find.text('Add a new address'));
    await h.settle(tester);
    expect(find.byType(AddressPage), findsOneWidget);
    h.http
      ..onPost(_addresses, (s) => s.reply(201, address()))
      ..onGet(_addresses, (s) => s.reply(200, addressList([address()])));
    await tester.enterText(find.byType(TextField).at(1), 'House 1, Road 2');
    await tester.tap(find.text('Save address'));
    await h.settle(tester);
    expect(find.text('Rahim Uddin'), findsOneWidget);
  });

  testWidgets('without a selection the customer goes back to the service', (
    tester,
  ) async {
    final h = await _start(tester);
    await h.pumpApp(tester, Routes.providersOf(electricianId));
    expect(
      find.text('Choose what you need on the service page first.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Choose items'));
    await h.settle(tester);
    expect(find.byType(ServicePage), findsOneWidget);
  });
}
