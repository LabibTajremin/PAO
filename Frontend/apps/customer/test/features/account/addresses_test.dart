import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/account/presentation/addresses_page.dart';
import 'package:pao_customer/features/location/presentation/address_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';

const _path = '/v1/customer/addresses';

Map<String, Object?> _address(
  String id, {
  String label = 'home',
  bool isDefault = false,
  String? area = 'Banani',
}) => {
  'id': id,
  'label': label,
  'line1': 'House $id',
  'area': ?area,
  'location': {'lat': 23.79, 'lng': 90.4},
  'isDefault': isDefault,
};

Future<Harness> _start(
  WidgetTester tester,
  List<Map<String, Object?>> items,
) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http.onGet(_path, (s) => s.reply(200, {'items': items}));
  await h.pumpApp(tester, Routes.accountPage('addresses'));
  return h;
}

Future<void> _menu(
  WidgetTester tester,
  Harness h,
  int index,
  String item,
) async {
  await tester.tap(find.byTooltip('Address actions').at(index));
  await h.settle(tester);
  await tester.tap(find.text(item).last);
  await h.settle(tester);
}

void main() {
  testWidgets('saved addresses show labels, default and change it (C24)', (
    tester,
  ) async {
    final h = await _start(tester, [
      _address('a1', isDefault: true),
      _address('a2', label: 'office', area: null),
      _address('a3', label: 'other'),
    ]);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('House a1, Banani'), findsOneWidget);
    expect(find.text('House a2'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.byTooltip('Address actions').first);
    await h.settle(tester);
    expect(find.text('Make default'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await h.settle(tester);
    h.http.onPost(
      '$_path/a2/default',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await _menu(tester, h, 1, 'Make default');
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsOneWidget,
    );
    h.http
      ..onPost('$_path/a2/default', (s) => s.reply(200, _address('a2')))
      ..onGet(
        _path,
        (s) => s.reply(200, {
          'items': [_address('a2', label: 'office', isDefault: true)],
        }),
      );
    await _menu(tester, h, 1, 'Make default');
    expect(find.text('Home'), findsNothing);
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('delete asks first; edit and add open the address form', (
    tester,
  ) async {
    final h = await _start(tester, [_address('a1')]);
    await _menu(tester, h, 0, 'Delete');
    expect(find.text('Delete this address?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.method == 'DELETE'), isEmpty);
    h.http
      ..onDelete('$_path/a1', (s) => s.reply(204, null))
      ..onGet(_path, (s) => s.reply(200, {'items': <Object?>[]}));
    await _menu(tester, h, 0, 'Delete');
    await tester.tap(find.text('Delete').last);
    await h.settle(tester);
    expect(h.sent.where((o) => o.method == 'DELETE'), hasLength(1));
    expect(find.text('No saved addresses'), findsOneWidget);
    await tester.tap(find.text('Add address'));
    await h.settle(tester);
    expect(find.byType(AddressPage), findsOneWidget);
    h.http.onGet(
      _path,
      (s) => s.reply(200, {
        'items': [_address('a9')],
      }),
    );
    Navigator.of(tester.element(find.byType(AddressPage))).pop();
    await h.settle(tester);
    expect(find.text('House a9, Banani'), findsOneWidget);
    await _menu(tester, h, 0, 'Edit');
    expect(find.byType(AddressPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(AddressPage))).pop();
    await h.settle(tester);
    expect(find.byType(AddressesPage), findsOneWidget);
  });

  testWidgets('ten addresses is the limit; a failed load retries', (
    tester,
  ) async {
    final h = await _start(tester, [
      for (var i = 0; i < 10; i++) _address('a$i'),
    ]);
    expect(find.text('You can save up to 10 addresses.'), findsOneWidget);
    await tester.tap(find.text('Add address'));
    await h.settle(tester);
    expect(find.byType(AddressesPage), findsOneWidget);
    h.http.onGet(_path, (s) => s.reply(503, apiError('INTERNAL')));
    await h.go(tester, Routes.account);
    await h.go(tester, Routes.accountPage('addresses'));
    expect(find.byType(PaoErrorState), findsOneWidget);
    h.http.onGet(
      _path,
      (s) => s.reply(200, {
        'items': [_address('a1')],
      }),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Add address'), findsOneWidget);
  });
}
