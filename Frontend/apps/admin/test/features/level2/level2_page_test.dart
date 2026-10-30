import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _sessions = '/v1/admin/level2-sessions';

Future<Harness> _open(
  WidgetTester tester,
  List<Map<String, Object?>> sessions, {
  List<String>? permissions,
}) async {
  final h = Harness.create();
  await h.signIn(tester, permissions: permissions);
  h.http
    ..onGet(_sessions, (s) => s.reply(200, {'items': sessions}))
    ..onGet(
      '/v1/admin/providers/$providerId',
      (s) => s.reply(200, providerDetail()),
    )
    ..onGet(
      '/v1/admin/providers/prov-0002',
      (s) => s.reply(404, apiError('NOT_FOUND')),
    );
  await h.pumpApp(tester, Routes.level2);
  return h;
}

Map<String, Object?> _list(Harness h) =>
    h.sent.lastWhere((o) => o.path == _sessions).queryParameters;

void main() {
  testWidgets('sessions show names, falling back to short IDs', (tester) async {
    desktop(tester);
    await _open(tester, [
      sessionJson(),
      sessionJson(
        id: 'sess-2',
        provider: 'prov-0002',
        service: 'serv-0002-plumbing',
        status: 'completed',
        result: 'fail',
      ),
      sessionJson(id: 'sess-3', service: 'serv-0003', status: 'cancelled'),
    ]);
    expect(find.text('Level 2 sessions'), findsWidgets);
    expect(find.text('Rahim Uddin'), findsNWidgets(2));
    expect(find.text('Electrician'), findsOneWidget);
    expect(find.text('prov-000'), findsOneWidget);
    expect(find.text('serv-000'), findsNWidgets(2));
    expect(find.text('12 Oct 2026, 10:00 AM'), findsNWidgets(3));
    expect(find.widgetWithText(PaoBadge, 'Fail'), findsOneWidget);
    expect(find.widgetWithText(PaoBadge, 'Scheduled'), findsOneWidget);
    expect(find.widgetWithText(PaoBadge, 'Cancelled'), findsOneWidget);
  });

  testWidgets('the status filter asks the API for that status', (tester) async {
    narrow(tester);
    final h = await _open(tester, []);
    expect(find.text('No sessions match.'), findsOneWidget);
    await tester.tap(find.byType(DropdownMenu<Level2SessionStatusEnum?>));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Completed').last);
    await h.settle(tester);
    expect(_list(h)['status'], 'completed');
  });

  testWidgets('the provider filter searches and can be cleared', (
    tester,
  ) async {
    desktop(tester);
    final h = await _open(tester, [sessionJson()]);
    await tester.tap(find.text('Provider: Any'));
    await tester.pumpAndSettle();
    h.http.onGet(
      '/v1/admin/providers',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await tester.enterText(find.byType(TextField).last, 'rahim');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle(tester);
    expect(h.sent.last.queryParameters['q'], 'rahim');
    expect(h.sent.last.queryParameters['level'], isNull);
    h.http.onGet(
      '/v1/admin/providers',
      (s) => s.reply(200, {'items': <Object?>[]}),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('No provider matches.'), findsOneWidget);
    h.http.onGet(
      '/v1/admin/providers',
      (s) => s.reply(200, {
        'items': [providerJson(phone: null)],
      }),
    );
    await tester.enterText(find.byType(TextField).last, 'rahim');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle(tester);
    expect(find.text('Level 1 · Verified'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Rahim Uddin'));
    await h.settle(tester);
    expect(_list(h)['providerId'], providerId);
    expect(find.text('Provider: Rahim Uddin'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await h.settle(tester);
    expect(_list(h)['providerId'], isNull);
    await tester.tap(find.text('Provider: Any'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(find.text('Provider: Any'), findsOneWidget);
  });

  testWidgets('a failed list can be retried; limited admins see less', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester, permissions: ['level2:manage']);
    h.http.onGet(_sessions, (s) => s.reply(500, apiError('INTERNAL')));
    await h.pumpApp(tester, Routes.level2);
    expect(find.text('Schedule session'), findsNothing);
    expect(find.text('Provider: Any'), findsNothing);
    h.http.onGet(
      _sessions,
      (s) => s.reply(200, {
        'items': [sessionJson()],
      }),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('prov-000'), findsOneWidget);
    expect(
      h.sent.where((o) => o.path.startsWith('/v1/admin/providers')),
      isEmpty,
    );
  });
}
