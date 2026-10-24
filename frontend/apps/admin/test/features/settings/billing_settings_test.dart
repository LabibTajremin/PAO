import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/billing/presentation/billing_labels.dart';
import 'package:pao_admin/features/settings/presentation/billing_settings.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';

import 'fixtures.dart';

Future<void> _edit(WidgetTester tester, String key) async {
  final row = find.widgetWithText(ListTile, key);
  await tester.tap(
    find.descendant(of: row, matching: find.byTooltip('Change setting')),
  );
  await tester.pumpAndSettle();
}

Future<void> _value(WidgetTester tester, String text) async {
  await tester.enterText(inDialog(find.byType(TextField)), text);
  await tester.tap(inDialog(find.text('Save')));
  await tester.pump();
}

void main() {
  test('rates read as percentages; unknown keys and values pass through', () {
    final t = lookupAdminL10n(const Locale('en'));
    expect(percentOf(1000), '10');
    expect(percentOf(1050), '10.5');
    expect(percentOf(1005), '10.05');
    expect(billingSettingValue(t, commissionRateKey, 'x'), isNull);
    expect(billingSettingValue(t, 'other', '5'), isNull);
    expect(checkBillingSetting(t, 'other', 'x'), isNull);
    expect(billingSettingHint(t, 'other'), isNull);
    expect(shortId('ab12cd34-0000'), 'ab12cd34');
    expect(
      [for (final m in PaymentMethodKind.values) paymentMethodLabel(t, m)],
      ['Cash to agent', 'bKash', 'Nagad', 'Bank transfer'],
    );
  });

  testWidgets('billing settings are shown and checked by their meaning', (
    tester,
  ) async {
    final h = await openSettings(tester, Routes.settingsTab('nope'));
    h.http.onGet(
      settingsPath,
      (s) => s.reply(200, {
        'items': [
          setting(commissionRateKey, 'integer', '1000'),
          setting(dueBlockKey, 'integer', '50000'),
        ],
      }),
    );
    await h.go(tester, Routes.settings);
    expect(find.text('10% (1000 bp)'), findsOneWidget);
    expect(find.text('৳500'), findsOneWidget);

    await _edit(tester, commissionRateKey);
    expect(find.textContaining('1000 = 10% of the final'), findsOneWidget);
    for (final bad in ['10001', '-1', 'ten']) {
      await _value(tester, bad);
      expect(find.textContaining('from 0 to 10000'), findsOneWidget);
    }
    const ratePath = '$settingsPath/$commissionRateKey';
    h.http.onPut(
      ratePath,
      (s) => s.reply(200, setting(commissionRateKey, 'integer', '1050')),
    );
    await _value(tester, '1050');
    await h.settle(tester);
    expect(h.bodyOf(ratePath), {'value': '1050'});

    await _edit(tester, dueBlockKey);
    expect(find.textContaining('50000 = ৳500'), findsOneWidget);
    await _value(tester, '-5');
    expect(find.textContaining('0 or more'), findsOneWidget);
    const duePath = '$settingsPath/$dueBlockKey';
    h.http.onPut(
      duePath,
      (s) => s.reply(200, setting(dueBlockKey, 'integer', '0')),
    );
    await _value(tester, '0');
    await h.settle(tester);
    expect(h.bodyOf(duePath), {'value': '0'});
  });
}
