import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/shared/detail_drawer.dart';
import 'package:pao_api/pao_api.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _subs = '/v1/admin/catalog/sub-services';
const _prices = '$_subs/$subId/prices';

Future<Harness> _open(WidgetTester tester) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester);
  h.http.onGet(catalogPath, (s) => s.reply(200, tree()));
  await h.pumpApp(tester, Routes.serviceOf(serviceId));
  await reveal(tester, find.text('Socket repair'));
  return h;
}

/// Taps [target] inside the open dialog after scrolling it into view.
Future<void> _tapIn(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, Harness h) async {
  await _tapIn(tester, _d(find.text('Save')));
  await h.settle(tester);
}

/// [target] inside the open dialog, not on the editor behind it.
Finder _d(Finder target) =>
    find.descendant(of: find.byType(AlertDialog), matching: target);

/// The field labelled [label] in the open dialog, or the price drawer.
Finder _f(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AlertDialog || w is DetailPanel),
  matching: field(label),
);

void main() {
  testWidgets('a sub-service is checked, refused, then added', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.text('New sub-service'));
    await tester.pumpAndSettle();
    await tester.enterText(_f('Description (English)'), 'One visit');
    await tester.enterText(_f('Most per booking'), '0');
    await tester.enterText(_f('Price'), 'abc');
    await _save(tester, h);
    expect(find.text('Fill this in.'), findsNWidgets(3));
    expect(find.text('Enter 1 or more.'), findsOneWidget);
    expect(
      find.text('Enter an amount in taka, such as 500 or 499.50.'),
      findsOne,
    );
    await tester.enterText(_f('Name (English)'), 'Fan repair');
    await tester.enterText(_f('Name (Bangla)'), 'ফ্যান মেরামত');
    await tester.enterText(_f('Description (Bangla)'), 'এক ভিজিট');
    await tester.enterText(_f('Most per booking'), '');
    await tester.enterText(_f('Price'), '450.5');
    await _tapIn(tester, _d(find.text('Add')).first);
    await tester.enterText(_f('Included 1 (English)'), 'Parts check');
    await tester.enterText(_f('Included 1 (Bangla)'), 'যন্ত্রাংশ পরীক্ষা');
    await _tapIn(tester, _d(find.text('Add')).last);
    await _tapIn(tester, _d(find.byTooltip('Remove')).last);
    await _tapIn(tester, find.byType(DropdownButtonFormField<PriceUnit>));
    await tester.tap(find.text('per hour').last);
    await tester.pumpAndSettle();
    await _tapIn(tester, _d(find.byType(Switch)));
    h.http.onPost(_subs, (s) => s.reply(500, apiError('INTERNAL')));
    await _save(tester, h);
    expect(find.text('Our service had a problem. Please try again.'), findsOne);
    h.http.onPost(_subs, (s) => s.reply(201, subService()));
    await _save(tester, h);
    expect(find.text('Saved.'), findsOneWidget);
    expect(h.bodyOf(_subs), {
      'serviceId': serviceId,
      'name': {'en': 'Fan repair', 'bn': 'ফ্যান মেরামত'},
      'description': {'en': 'One visit', 'bn': 'এক ভিজিট'},
      'inclusions': [
        {'en': 'Parts check', 'bn': 'যন্ত্রাংশ পরীক্ষা'},
      ],
      'exclusions': <Object>[],
      'unit': 'hour',
      'initialPrice': 45050,
      'published': true,
    });
  });

  testWidgets('a sub-service is edited without a price field', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.byTooltip('Edit sub-service').first);
    await tester.pumpAndSettle();
    expect(_f('Price'), findsNothing);
    await tester.enterText(_f('Most per booking'), '6');
    await tester.enterText(_f('Description (English)'), '');
    await tester.enterText(_f('Description (Bangla)'), '');
    const path = '$_subs/$subId';
    h.http.onPut(path, (s) => s.reply(200, subService()));
    await _save(tester, h);
    expect(h.bodyOf(path), {
      'serviceId': serviceId,
      'name': named('Ceiling fan installation'),
      'inclusions': [named('Wiring check')],
      'exclusions': <Object>[],
      'unit': 'unit',
      'maxQuantity': 6,
      'published': true,
    });
    await tester.tap(find.byTooltip('Edit sub-service').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Edit sub-service'), findsNothing);
  });

  testWidgets('prices: history, a refused and an accepted change', (
    tester,
  ) async {
    final h = await _open(tester);
    h.http.onGet(
      _prices,
      (s) => s.reply(200, {
        'items': [
          priceVersion(45000, '2026-09-01T00:00:00Z'),
          priceVersion(50000, '2026-10-01T04:00:00Z'),
        ],
      }),
    );
    await tester.tap(find.byTooltip('Prices').first);
    await h.settle(tester);
    expect(find.text('Prices of Ceiling fan installation'), findsOneWidget);
    expect(find.text('From 1 Oct 2026, 10:00 AM · by b0000000'), findsOne);
    final current = find.widgetWithText(ListTile, '৳500');
    expect(
      find.descendant(of: current, matching: find.text('Current')),
      findsOneWidget,
    );
    await tester.tap(find.text('Set new price'));
    await tester.pump();
    expect(find.text('Fill this in.'), findsOneWidget);
    await tester.enterText(_f('New price (per unit)'), '550');
    h.http.onPost(_prices, (s) => s.reply(422, apiError('VALIDATION_FAILED')));
    await tester.tap(find.text('Set new price'));
    await h.settle(tester);
    expect(find.text('Please check the highlighted fields.'), findsOneWidget);
    h.http.onPost(
      _prices,
      (s) => s.reply(201, priceVersion(55000, '2026-10-09T04:00:00Z')),
    );
    await tester.tap(find.text('Set new price'));
    await h.settle(tester);
    expect(find.text('Price updated.'), findsOneWidget);
    final change = h.sent.lastWhere((o) => o.method == 'POST').data;
    expect(jsonDecode(change! as String), {'amount': 55000});
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Set new price'), findsNothing);
  });

  testWidgets('an empty price history, after a failed load', (tester) async {
    final h = await _open(tester);
    h.http.onGet(_prices, (s) => s.reply(500, apiError('INTERNAL')));
    await tester.tap(find.byTooltip('Prices').first);
    await h.settle(tester);
    h.http.onGet(_prices, (s) => s.reply(200, {'items': <Object>[]}));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('No prices recorded yet.'), findsOneWidget);
  });
}
