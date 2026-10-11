import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/shared/detail_drawer.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _sessions = '/v1/admin/level2-sessions';
const _one = '$_sessions/$sessionId';

Map<String, Object?> _service() => {
  'id': serviceId,
  'categoryId': 'cat-1',
  'name': {'en': 'Electrician', 'bn': 'ইলেকট্রিশিয়ান'},
  'iconKey': 'bolt',
  'serviceModel': 'on_demand',
  'requiredLevel': 1,
  'searchRadiusM': 5000,
  'womenProvidersOnly': false,
  'requiresLevel2': true,
  'level2Checklist': [
    {'en': 'Safe wiring', 'bn': 'নিরাপদ তার'},
  ],
  'published': true,
};

Future<Harness> _open(
  WidgetTester tester,
  Map<String, Object?> session, {
  List<String>? permissions,
}) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester, permissions: permissions);
  h.http
    ..onGet(
      _sessions,
      (s) => s.reply(200, {
        'items': [session],
      }),
    )
    ..onGet(_one, (s) => s.reply(200, session))
    ..onGet(
      '/v1/admin/providers/$providerId',
      (s) => s.reply(200, providerDetail()),
    )
    ..onGet(
      '/v1/customer/services/$serviceId',
      (s) => s.reply(200, _service()),
    );
  await h.pumpApp(tester, Routes.level2);
  await tester.tap(find.text('PAO office, Gulshan 1'));
  await h.settle(tester);
  return h;
}

Finder _inDrawer(String text) =>
    find.descendant(of: find.byType(DetailPanel), matching: find.text(text));

void main() {
  testWidgets('record a result from the service checklist plus an item', (
    tester,
  ) async {
    final h = await _open(
      tester,
      sessionJson(),
      permissions: [...superAdminPermissions, 'catalog:read'],
    );
    expect(_inDrawer('Rahim Uddin'), findsOneWidget);
    expect(_inDrawer('Safe wiring'), findsOneWidget);
    await tester.ensureVisible(find.text('Record result'));
    await tester.tap(find.text('Record result'));
    await tester.pumpAndSettle();
    expect(find.text('Choose pass, fail or retest.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Add a checklist item'),
      'Tool use',
    );
    await tester.tap(find.byTooltip('Add a checklist item'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Add a checklist item'),
      'Earthing',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Safe wiring'));
    await tester.tap(find.widgetWithText(PaoChip, 'Pass'));
    await tester.enterText(
      find.widgetWithText(PaoTextField, 'Notes'),
      ' Neat work ',
    );
    await tester.pumpAndSettle();
    expect(find.text('Passed'), findsOneWidget);
    h.http.onPost(
      '$_one/result',
      (s) => s.reply(
        200,
        sessionJson(
          status: 'completed',
          result: 'pass',
          checklist: [
            {'item': 'Safe wiring', 'passed': true},
            {'item': 'Tool use', 'passed': false},
          ],
          notes: 'Neat work',
        ),
      ),
    );
    await tester.ensureVisible(find.text('Record result'));
    await tester.tap(find.text('Record result'));
    await h.settle(tester);
    expect(h.bodyOf('$_one/result'), {
      'result': 'pass',
      'checklist': [
        {'item': 'Safe wiring', 'passed': true},
        {'item': 'Tool use', 'passed': false},
        {'item': 'Earthing', 'passed': false},
      ],
      'notes': 'Neat work',
    });
    expect(find.widgetWithText(PaoBadge, 'Pass'), findsWidgets);
    expect(_inDrawer('Notes: Neat work'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(h.sent.where((o) => o.path == _sessions), hasLength(2));
  });

  testWidgets('without the catalog the checklist starts empty; errors show', (
    tester,
  ) async {
    final h = await _open(
      tester,
      sessionJson(),
      permissions: ['level2:manage', 'provider:read'],
    );
    expect(h.sent.where((o) => o.path.startsWith('/v1/customer')), isEmpty);
    await tester.tap(find.widgetWithText(PaoChip, 'Retest'));
    await tester.tap(find.byTooltip('Add a checklist item'));
    await tester.ensureVisible(find.text('Record result'));
    await tester.tap(find.text('Record result'));
    await tester.pumpAndSettle();
    expect(find.text('Add at least one checklist item.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Add a checklist item'),
      'Tool use',
    );
    await tester.tap(find.byTooltip('Add a checklist item'));
    await tester.pumpAndSettle();
    h.http.onPost(
      '$_one/result',
      (s) => s.reply(409, apiError('SESSION_CLOSED')),
    );
    await tester.ensureVisible(find.text('Record result'));
    await tester.tap(find.text('Record result'));
    await h.settle(tester);
    expect(find.text('This Level 2 session is closed.'), findsOneWidget);
    expect(h.bodyOf('$_one/result'), {
      'result': 'retest',
      'checklist': [
        {'item': 'Tool use', 'passed': false},
      ],
    });
  });

  testWidgets('a closed session shows its result; viewers cannot record', (
    tester,
  ) async {
    await _open(
      tester,
      sessionJson(status: 'completed', result: 'fail', notes: ''),
    );
    expect(_inDrawer('Completed'), findsOneWidget);
    expect(find.text('Record result'), findsNothing);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(DetailPanel), findsNothing);
  });

  testWidgets('a failed session can be retried', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester, permissions: ['provider:read', 'catalog:read']);
    h.http
      ..onGet(
        _sessions,
        (s) => s.reply(200, {
          'items': [sessionJson()],
        }),
      )
      ..onGet(_one, (s) => s.reply(500, apiError('INTERNAL')));
    await h.pumpApp(tester, Routes.level2);
    await tester.tap(find.text('PAO office, Gulshan 1'));
    await h.settle(tester);
    h.http.onGet(_one, (s) => s.reply(200, sessionJson()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(_inDrawer('Scheduled'), findsOneWidget);
    expect(find.text('Record result'), findsNothing);
  });
}
