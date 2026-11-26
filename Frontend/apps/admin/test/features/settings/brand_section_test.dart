import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/settings/presentation/brand_section.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _tagline = '{"en":"Ask for it. PAO it.","bn":"যা চাও, তাই PAO"}';

Future<Harness> _open(
  WidgetTester tester, {
  List<String>? permissions,
  String value = _tagline,
}) async {
  desktop(tester);
  final h = Harness.create();
  h.http.onGet(
    settingsPath,
    (s) => s.reply(200, {
      'items': [
        setting(taglineKey, 'tagline', value),
        setting('booking.cash_only', 'boolean', 'true'),
      ],
    }),
  );
  await h.signIn(tester, permissions: permissions);
  await h.pumpApp(tester, Routes.settings);
  return h;
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

void main() {
  testWidgets('the tagline is edited in its own section with a preview', (
    tester,
  ) async {
    final h = await _open(tester);
    expect(find.text('Brand'), findsOneWidget);
    expect(find.widgetWithText(ListTile, taglineKey), findsNothing);
    expect(find.text('যা চাও, তাই PAO'), findsWidgets);
    await tester.tap(find.widgetWithText(ActionChip, 'Need it? PAO it.'));
    await tester.pump();
    expect(find.text('Need it? PAO it.'), findsNWidgets(3));
    await tester.enterText(_field('Tagline (Bangla)').first, ' ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Fill this in.'), findsOneWidget);
    await tester.enterText(_field('Tagline (Bangla)').first, 'x' * 41);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Keep it to 40 characters or fewer.'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'চাইলেই PAO'));
    h.http.onPut(
      '$settingsPath/$taglineKey',
      (s) => s.reply(422, apiError('SETTING_INVALID')),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsNothing);
    h.http.onPut(
      '$settingsPath/$taglineKey',
      (s) => s.reply(200, setting(taglineKey, 'tagline', _tagline)),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved.'), findsOneWidget);
    expect(lastBody(h, 'PUT'), {
      'value': '{"en":"Need it? PAO it.","bn":"চাইলেই PAO"}',
    });
  });

  testWidgets('read-only admins see the tagline without the editor', (
    tester,
  ) async {
    await _open(tester, permissions: ['settings:read'], value: 'not json');
    expect(find.text('Brand'), findsOneWidget);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('Save'), findsNothing);
  });

  test('damaged values read as an empty tagline', () {
    expect(readTagline('[1]'), (en: '', bn: ''));
    expect(readTagline('{"en":"a"}'), (en: 'a', bn: ''));
  });
}
