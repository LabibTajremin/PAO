import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/level2/presentation/schedule_dialog.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _sessions = '/v1/admin/level2-sessions';

Finder get _submit => find.widgetWithText(PaoButton, 'Schedule');

Future<void> _pickDay(WidgetTester tester, String day, {bool ok = true}) async {
  await tester.tap(find.textContaining('Date: '));
  await tester.pumpAndSettle();
  await tester.tap(find.text(day));
  await tester.tap(find.text(ok ? 'OK' : 'Cancel').last);
  await tester.pumpAndSettle();
}

Future<Harness> _open(WidgetTester tester) async {
  desktop(tester);
  final h = Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(_sessions, (s) => s.reply(200, {'items': <Object?>[]}))
    ..onGet(
      '/v1/admin/providers',
      (s) => s.reply(200, {
        'items': [
          providerJson(services: []),
          providerJson(id: 'prov-2', name: 'Karim Mia'),
        ],
      }),
    );
  await h.pumpApp(tester, Routes.level2);
  await tester.tap(find.text('Schedule session'));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('schedule a session in Dhaka time after fixing mistakes', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a provider, a service and a location.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Find a provider'),
      'mia',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle(tester);
    expect(h.sent.last.queryParameters['level'], 1);
    await tester.tap(find.text('Rahim Uddin'));
    await tester.pumpAndSettle();
    expect(
      find.text('This provider has not chosen any service.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karim Mia'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Electrician').last);
    await tester.pumpAndSettle();
    expect(find.text('Date: Sat 10 Oct 2026'), findsOneWidget);
    await _pickDay(tester, '9');
    await tester.enterText(
      find.widgetWithText(PaoTextField, 'Location'),
      'PAO office',
    );
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(find.text('Choose a time in the future.'), findsOneWidget);
    await _pickDay(tester, '14', ok: false);
    await _pickDay(tester, '12');
    await tester.tap(find.textContaining('Time (Dhaka): '));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Time (Dhaka): 10:00 AM'), findsOneWidget);
    h.http.onPost(
      _sessions,
      (s) => s.reply(409, apiError('LEVEL2_NOT_ELIGIBLE')),
    );
    await tester.tap(_submit);
    await h.settle(tester);
    expect(
      find.text('Only Level 1 providers can take a Level 2 session.'),
      findsOneWidget,
    );
    h.http.onPost(_sessions, (s) => s.reply(201, sessionJson()));
    await tester.tap(_submit);
    await h.settle(tester);
    final sent = h.sent.lastWhere((o) => o.method == 'POST').data;
    expect(sent is String ? jsonDecode(sent) : sent, {
      'providerId': 'prov-2',
      'serviceId': serviceId,
      'scheduledAt': '2026-10-12T04:00:00.000Z',
      'location': 'PAO office',
    });
    expect(find.byType(ScheduleForm), findsNothing);
    expect(
      find.text('Session scheduled. The provider will be notified.'),
      findsOneWidget,
    );
  });

  testWidgets('the cooling-off error is worded for the admin; cancel closes', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Find a provider'),
      'karim',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle(tester);
    await tester.tap(find.text('Karim Mia'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(PaoTextField, 'Location'),
      'Gulshan',
    );
    h.http.onPost(
      _sessions,
      (s) => s.reply(409, apiError('LEVEL2_COOLING_OFF')),
    );
    await tester.tap(_submit);
    await h.settle(tester);
    expect(
      find.text('This provider failed recently and must wait before retrying.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(find.byType(ScheduleForm), findsNothing);
    expect(h.sent.where((o) => o.path == _sessions), hasLength(2));
  });

  test('Dhaka days and instants', () {
    expect(dhakaDay(DateTime.utc(2026, 10, 9, 20)), DateTime(2026, 10, 10));
    expect(
      dhakaInstant(
        DateTime(2026, 10, 10),
        const TimeOfDay(hour: 5, minute: 30),
      ),
      DateTime.utc(2026, 10, 9, 23, 30),
    );
  });
}
