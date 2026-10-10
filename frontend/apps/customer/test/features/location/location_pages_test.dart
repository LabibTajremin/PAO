import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/home/presentation/home_page.dart';
import 'package:pao_customer/features/location/presentation/map_picker.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _addresses = '/v1/customer/addresses';
const _area = '/v1/customer/service-area';

Finder _field(int i) => find.byType(TextField).at(i);

String _text(WidgetTester tester, int i) =>
    tester.widget<TextField>(_field(i)).controller!.text;

Future<Harness> _start(WidgetTester tester, {FakePlaces? places}) async {
  tall(tester);
  final h = await Harness.create(places: places ?? FakePlaces());
  await h.signIn(tester);
  h.http.onGet(_area, (s) => s.reply(200, coverage()));
  return h;
}

void main() {
  testWidgets('sign-up location: explain, locate, search, pin and save', (
    tester,
  ) async {
    final places = FakePlaces();
    final h = await _start(tester, places: places);
    await h.pumpApp(tester, Routes.location);
    expect(find.text('Find services near you'), findsOneWidget);
    await tester.tap(find.text('Allow location access'));
    await h.settle(tester);
    expect(_text(tester, 1), gulshan.title);
    expect(_text(tester, 3), 'Gulshan');
    expect(find.text('PAO works in Dhaka'), findsOneWidget);
    await tester.enterText(_field(0), 'Banani');
    await tester.pump(const Duration(milliseconds: 300));
    await h.settle(tester);
    await tester.tap(find.text(banani.title));
    await h.settle(tester);
    expect(_text(tester, 1), banani.title);
    expect(places.queries, ['en:Banani']);
    h.http.onGet(_area, (s) => s.reply(200, coverage(covered: false)));
    await tester.drag(find.byType(MapPicker), const Offset(0, 100));
    await h.settle(tester);
    expect(find.text('We are not here yet'), findsOneWidget);
    await tester.tap(find.text('Office'));
    await h.settle(tester);
    await _save(tester, h);
  });

  testWidgets('without a position the customer types the address', (
    tester,
  ) async {
    final h = await _start(tester);
    h.location.point = null;
    await h.pumpApp(tester, Routes.location);
    await tester.tap(find.text('Enter address manually'));
    await h.settle(tester);
    expect(find.text('Your pin'), findsOneWidget);
    await tester.tap(find.text('Use my current location'));
    await h.settle(tester);
    expect(find.textContaining('could not find your location'), findsOneWidget);
  });

  testWidgets('a new address from the account opens the addresses list', (
    tester,
  ) async {
    final h = await _start(tester);
    await h.pumpApp(tester, Routes.addressNew);
    expect(find.text('Add address'), findsOneWidget);
    h.http
      ..onGet(_addresses, (s) => s.reply(200, addressList([address()])))
      ..onPost(_addresses, (s) => s.reply(201, address(isDefault: false)));
    await tester.enterText(_field(1), 'House 9, Road 1');
    await tester.tap(find.text('Save address'));
    await h.settle(tester);
    expect((h.bodyOf(_addresses)! as Map)['isDefault'], isFalse);
    expect(find.byType(PlaceholderPage), findsOneWidget);
  });

  testWidgets('editing loads the address and saves it back', (tester) async {
    final h = await _start(tester);
    h.http.onGet(
      _addresses,
      (s) => s.reply(200, addressList([address(label: 'office')])),
    );
    await h.pumpApp(tester, Routes.addressEdit('missing'));
    expect(find.text('Edit address'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await h.go(tester, Routes.addressEdit(homeAddressId));
    await h.settle(tester);
    expect(_text(tester, 1), 'House 12, Road 5, Block C');
    expect(_text(tester, 2), 'Flat 3B');
    expect(find.text('PAO works in Dhaka'), findsOneWidget);
    h.http.onPut('$_addresses/$homeAddressId', (s) => s.reply(200, address()));
    await tester.tap(find.text('Save address'));
    await h.settle(tester);
    expect(h.bodyOf('$_addresses/$homeAddressId'), {
      'label': 'office',
      'line1': 'House 12, Road 5, Block C',
      'line2': 'Flat 3B',
      'area': 'Banani',
      'location': {'lat': 23.794, 'lng': 90.407},
      'isDefault': true,
    });
    expect(find.byType(PlaceholderPage), findsOneWidget);
  });
}

Future<void> _save(WidgetTester tester, Harness h) async {
  await tester.enterText(_field(1), 'ab');
  await tester.tap(find.text('Save address'));
  await h.settle(tester);
  expect(find.text('Enter 3 to 200 characters.'), findsOneWidget);
  h.http
    ..onGet(_addresses, (s) => s.reply(200, addressList([])))
    ..onPost(
      _addresses,
      (s) => s.reply(409, apiError('ADDRESS_LIMIT_REACHED')),
    );
  await tester.enterText(_field(1), ' House 12, Road 5 ');
  await tester.enterText(_field(2), '  ');
  await tester.tap(find.text('Save address'));
  await h.settle(tester);
  expect(
    find.text('You have saved the most addresses allowed.'),
    findsOneWidget,
  );
  h.http.onPost(_addresses, (s) => s.reply(201, address()));
  await tester.tap(find.text('Save address'));
  await h.settle(tester);
  final post = h.sent.lastWhere((o) => o.method == 'POST');
  final body = jsonDecode(post.data as String) as Map<String, Object?>;
  expect(body, containsPair('label', 'office'));
  expect(body, containsPair('line1', 'House 12, Road 5'));
  expect(body, containsPair('isDefault', true));
  expect(body.containsKey('line2'), isFalse);
  expect(
    ((body['location']! as Map)['lat']! as num) > banani.point.lat,
    isTrue,
  );
  expect(find.byType(HomePage), findsOneWidget);
}
