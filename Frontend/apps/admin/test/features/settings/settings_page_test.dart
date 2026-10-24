import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _timeout = 'booking.accept_timeout_asap_seconds';

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
}

void main() {
  testWidgets('tabs follow permissions', (tester) async {
    final h = await openSettings(
      tester,
      Routes.settings,
      permissions: ['audit:read', 'dashboard:read'],
    );
    expect(find.text('Audit log'), findsOneWidget);
    expect(find.text('Platform settings'), findsNothing);
    await h.go(tester, Routes.settingsTab('roles'));
    expect(find.text('Audit log'), findsOneWidget);
  });

  testWidgets('without any settings permission the screen is denied', (
    tester,
  ) async {
    await openSettings(tester, Routes.settings, permissions: []);
    expect(find.byType(PaoAccessDeniedView), findsOneWidget);
  });

  testWidgets('settings are listed, searched and edited by type', (
    tester,
  ) async {
    final h = await openSettings(tester, Routes.settingsTab('nope'));
    h.http.onGet(settingsPath, (s) => s.reply(200, settingList()));
    await h.go(tester, Routes.settings);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
    expect(find.text('Map shape'), findsOneWidget);
    expect(find.text('About rating.low_threshold'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'RATING');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.text(_timeout), findsNothing);
    await _edit(tester, 'rating.low_threshold');
    await _value(tester, 'x');
    await tester.pump();
    expect(find.text('Enter a number.'), findsOneWidget);
    await tester.tap(inDialog(find.text('Cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await _edit(tester, _timeout);
    await _value(tester, 'abc');
    await tester.pump();
    expect(find.text('Enter a whole number.'), findsOneWidget);
    const path = '$settingsPath/$_timeout';
    h.http.onPut(path, (s) => s.reply(422, apiError('SETTING_INVALID')));
    await _value(tester, '240');
    await h.settle(tester);
    expect(find.text('This value does not fit the setting.'), findsOneWidget);
    h.http.onPut(
      path,
      (s) => s.reply(200, setting(_timeout, 'integer', '240')),
    );
    await _value(tester, '240');
    await h.settle(tester);
    expect(find.text('Saved.'), findsOneWidget);
    expect(h.bodyOf(path), {'value': '240'});
  });

  testWidgets('switches, shapes and texts are checked before saving', (
    tester,
  ) async {
    final h = await openSettings(tester, Routes.dashboard);
    h.http
      ..onGet(settingsPath, (s) => s.reply(200, settingList()))
      ..onPut(
        '$settingsPath/booking.cash_only',
        (s) => s.reply(200, setting('booking.cash_only', 'boolean', 'false')),
      );
    await h.go(tester, Routes.settingsTab(''));
    await _edit(tester, 'booking.cash_only');
    await tester.tap(inDialog(find.byType(Switch)));
    await tester.tap(inDialog(find.text('Save')));
    await h.settle(tester);
    expect(lastBody(h, 'PUT'), {'value': 'false'});
    await _edit(tester, 'service.area');
    await _value(tester, '[1]');
    await tester.pump();
    expect(find.text('Paste a GeoJSON object with a "type".'), findsOne);
    await _value(tester, '{oops');
    await tester.pump();
    expect(find.text('Paste a GeoJSON object with a "type".'), findsOne);
    await tester.tap(inDialog(find.text('Cancel')));
    await tester.pumpAndSettle();
    await _edit(tester, 'support.phone');
    await _value(tester, 'x' * 20001);
    await tester.pump();
    expect(find.text('Keep it to 20000 characters or fewer.'), findsOne);
  });

  testWidgets('read-only, empty and failed settings', (tester) async {
    final h = await openSettings(
      tester,
      Routes.dashboard,
      permissions: ['settings:read'],
    );
    h.http.onGet(settingsPath, (s) => s.reply(200, settingList()));
    await h.go(tester, Routes.settings);
    expect(find.text('180'), findsOneWidget);
    expect(find.byTooltip('Change setting'), findsNothing);
    h.http.onGet(settingsPath, (s) => s.reply(200, {'items': <Object>[]}));
    await h.go(tester, Routes.dashboard);
    await h.go(tester, Routes.settings);
    expect(find.text('No settings yet'), findsOneWidget);
    h.http.onGet(settingsPath, (s) => s.reply(500, apiError('INTERNAL')));
    await h.go(tester, Routes.dashboard);
    await h.go(tester, Routes.settings);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a tab opens its own address', (tester) async {
    final h = await openSettings(tester, Routes.settings);
    h.http.onGet(rolesPath, (s) => s.reply(200, roleList()));
    await tester.tap(find.text('Roles'));
    await h.settle(tester);
    expect(find.text('Catalog manager'), findsOneWidget);
  });
}
