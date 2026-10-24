import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/home/presentation/home_parts.dart';
import 'package:pao_customer/features/home/presentation/services_page.dart';
import 'package:pao_customer/features/live/presentation/live_page.dart';
import 'package:pao_customer/features/location/presentation/address_page.dart';
import 'package:pao_customer/features/search/presentation/search_page.dart';
import 'package:pao_customer/features/service/presentation/service_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import '../location/fixtures.dart';
import '../service/fixtures.dart';

const _addresses = '/v1/customer/addresses';

Map<String, Object?> _booking(String status) => {
  'id': 'b1',
  'number': 'PAO-104233',
  'status': status,
  'serviceName': named('Electrician'),
  'total': 113000,
  'createdAt': '2026-10-09T04:00:00Z',
};

Future<Harness> _start(
  WidgetTester tester, {
  List<Map<String, Object?>>? addresses,
  String status = 'in_progress',
  bool covered = true,
}) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(
      _addresses,
      (s) => s.reply(
        200,
        addressList(
          addresses ??
              [
                address(),
                address(id: officeAddressId, label: 'office', isDefault: false),
              ],
        ),
      ),
    )
    ..onGet('/v1/customer/catalog', (s) => s.reply(200, catalog()))
    ..onGet(
      '/v1/customer/bookings',
      (s) => s.reply(200, {
        'items': [_booking('completed'), _booking(status)],
      }),
    )
    ..onGet(
      '/v1/customer/service-area',
      (s) => s.reply(200, coverage(covered: covered)),
    );
  await h.pumpApp(tester);
  return h;
}

void main() {
  testWidgets('home shows the address, categories and the running booking', (
    tester,
  ) async {
    final h = await _start(tester);
    expect(find.text('House 12, Road 5, Block C, Banani'), findsOneWidget);
    expect(find.text('Repairs'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
    expect(h.sent.last.queryParameters, {'lat': 23.794, 'lng': 90.407});
    await tester.tap(find.text('Track'));
    await h.settle(tester);
    expect(find.byType(LivePage), findsOneWidget);
    final pages = <String, Type>{
      'Search for a service': SearchPage,
      'Beauty': ServicePage,
      'Repairs': ServicesPage,
      'All services': ServicesPage,
    };
    for (final MapEntry(key: label, value: type) in pages.entries) {
      await h.go(tester, Routes.home);
      await tester.tap(find.text(label));
      await h.settle(tester);
      expect(find.byType(type), findsOneWidget, reason: label);
    }
  });

  testWidgets('the customer switches or adds an address', (tester) async {
    final h = await _start(tester, status: 'requested');
    expect(find.text('Waiting for the provider to accept'), findsOneWidget);
    h.http.onPost(
      '$_addresses/$officeAddressId/default',
      (s) => s.reply(200, address(id: officeAddressId, label: 'office')),
    );
    h.http.onGet(
      _addresses,
      (s) => s.reply(
        200,
        addressList([
          address(isDefault: false),
          address(id: officeAddressId, label: 'office', line1: 'Tower 7'),
        ]),
      ),
    );
    await tester.tap(find.text('House 12, Road 5, Block C, Banani'));
    await h.settle(tester);
    expect(find.text('Choose address'), findsOneWidget);
    await tester.tap(find.text('Office'));
    await h.settle(tester);
    expect(find.text('Tower 7, Banani'), findsOneWidget);
    h.http.onPost(
      '$_addresses/$homeAddressId/default',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await tester.tap(find.byType(AddressHeader));
    await h.settle(tester);
    await tester.tap(find.widgetWithText(PaoListRow, 'Home'));
    await h.settle(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AddressHeader));
    await h.settle(tester);
    final posts = h.sent.where((o) => o.method == 'POST').length;
    await tester.tap(find.widgetWithText(PaoListRow, 'Office'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.method == 'POST'), hasLength(posts));
    await tester.tap(find.byType(AddressHeader));
    await h.settle(tester);
    await tester.tapAt(const Offset(200, 20));
    await h.settle(tester);
    await tester.tap(find.byType(AddressHeader));
    await h.settle(tester);
    await tester.tap(find.text('Add a new address'));
    await h.settle(tester);
    expect(find.byType(AddressPage), findsOneWidget);
    h.http.onPost(_addresses, (s) => s.reply(201, address()));
    await tester.enterText(find.byType(TextField).at(1), 'House 1, Road 2');
    await tester.tap(find.text('Save address'));
    await h.settle(tester);
    expect(find.byType(AddressPage), findsNothing);
    expect(find.text('Repairs'), findsOneWidget);
  });

  testWidgets('without an address the customer is asked to add one', (
    tester,
  ) async {
    await _start(tester, addresses: []);
    expect(find.text('Set your address'), findsNWidgets(2));
    await tester.tap(find.widgetWithText(PaoButton, 'Add a new address'));
    await tester.pumpAndSettle();
    expect(find.byType(AddressPage), findsOneWidget);
  });

  testWidgets('an address outside the launch area offers another one', (
    tester,
  ) async {
    await _start(tester, covered: false);
    expect(find.text('We are not here yet'), findsOneWidget);
    expect(find.text('Repairs'), findsNothing);
    await tester.tap(find.text('Change address'));
    await tester.pumpAndSettle();
    expect(find.text('Choose address'), findsOneWidget);
  });

  testWidgets('home survives failures and an empty catalog', (tester) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http
      ..onGet(_addresses, (s) => s.reply(200, addressList([address()])))
      ..onGet('/v1/customer/catalog', (s) => s.reply(500, apiError('INTERNAL')))
      ..onGet('/v1/customer/bookings', (s) => s.reply(500, null))
      ..onGet('/v1/customer/service-area', (s) => s.reply(500, null));
    await h.pumpApp(tester);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(
      '/v1/customer/catalog',
      (s) => s.reply(200, {'version': 1, 'categories': <Object?>[]}),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('No services yet'), findsOneWidget);
    expect(find.text('Track'), findsNothing);
  });

  testWidgets('all services, one category, or none', (tester) async {
    final h = await _start(tester);
    await h.go(tester, Routes.services);
    expect(find.text('Repairs'), findsOneWidget);
    expect(find.text('Beauty'), findsOneWidget);
    await tester.tap(find.text('Driver'));
    await h.settle(tester);
    expect(find.byType(ServicePage), findsOneWidget);
    await h.go(tester, '${Routes.services}?category=c9');
    expect(find.text('No services yet'), findsOneWidget);
  });
}
