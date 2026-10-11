import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _e1 = 'f0000000-0000-4000-8000-000000000001';
const _e2 = 'f0000000-0000-4000-8000-000000000002';
const _e3 = 'f0000000-0000-4000-8000-000000000003';

Future<Harness> _open(WidgetTester tester) async {
  final h = await openSettings(tester, Routes.dashboard);
  h.http.onGet(
    auditPath,
    (s) => s.reply(200, {
      'items': [
        auditEntry(_e1),
        auditEntry(_e2, action: 'booking.timed_out', actor: false),
      ],
      'nextCursor': 'c2',
    }),
  );
  await h.go(tester, Routes.settingsTab('audit'));
  return h;
}

Finder _filter(String hint) => find.widgetWithText(TextField, hint);

void main() {
  testWidgets('entries page in and open with their changes', (tester) async {
    final h = await _open(tester);
    expect(find.text('Catalog manager · b0000000'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('8 Oct 2026, 12:30 PM'), findsNWidgets(2));
    h.http.onGet(
      auditPath,
      (s) => s.reply(200, {
        'items': [auditEntry(_e3, action: 'role.updated', role: false)],
      }),
    );
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(h.sent.last.queryParameters['cursor'], 'c2');
    expect(find.text('b0000000'), findsOneWidget);
    await tester.tap(find.text('catalog.price_changed'));
    await tester.pumpAndSettle();
    expect(find.text('Market rate'), findsOneWidget);
    expect(find.text('{\n  "amount": 50000\n}'), findsOneWidget);
    expect(find.text(rinaId), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('booking.timed_out'));
    await tester.pumpAndSettle();
    expect(find.text('Before'), findsNothing);
  });

  testWidgets('filters narrow the log and clear again', (tester) async {
    final h = await _open(tester);
    await tester.enterText(_filter('Actor ID'), 'rina');
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(find.text('Paste a full account ID.'), findsOneWidget);
    await tester.enterText(_filter('Actor ID'), rinaId);
    await tester.enterText(
      _filter('Action, e.g. catalog.price_changed'),
      ' role.updated ',
    );
    await tester.enterText(_filter('Subject ID'), 'verifier');
    await tester.tap(find.text('Any date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Any date'), findsOneWidget);
    await tester.tap(find.text('Any date'));
    await tester.pumpAndSettle();
    final dates = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dates.first, '10/01/2026');
    await tester.enterText(dates.last, '10/08/2026');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('1 Oct 2026 – 8 Oct 2026'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle(tester);
    expect(h.sent.last.queryParameters, {
      'actorId': rinaId,
      'action': 'role.updated',
      'subjectId': 'verifier',
      'from': DateTime.utc(2026, 9, 30, 18),
      'to': DateTime.utc(2026, 10, 8, 17, 59, 59),
      'limit': 20,
    });
    await tester.tap(find.text('Clear'));
    await h.settle(tester);
    expect(h.sent.last.queryParameters, {'limit': 20});
  });

  testWidgets('no entries, and a failed load', (tester) async {
    final h = await openSettings(tester, Routes.dashboard);
    h.http.onGet(auditPath, (s) => s.reply(200, {'items': <Object>[]}));
    await h.go(tester, Routes.settingsTab('audit'));
    expect(find.text('No audit entries match'), findsOneWidget);
    h.http.onGet(auditPath, (s) => s.reply(500, apiError('INTERNAL')));
    await tester.tap(find.text('Apply'));
    await h.settle(tester);
    expect(find.text('Try again'), findsOneWidget);
  });
}
