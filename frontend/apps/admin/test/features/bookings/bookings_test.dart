import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/bookings/presentation/booking_detail_page.dart';

import '../../support/harness.dart';
import '../providers/fixtures.dart';

const _list = '/v1/admin/bookings';

Map<String, Object?> _query(Harness h) =>
    h.sent.lastWhere((o) => o.path == _list).queryParameters;

void _reply(Harness h, List<Map<String, Object?>> rows) =>
    h.http.onGet(_list, (s) => s.reply(200, {'items': rows}));

void main() {
  testWidgets('the monitor filters by status, area and dates', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    _reply(h, [bookingSummary()]);
    await h.pumpApp(tester, Routes.bookings);
    expect(find.text('PAO-104233'), findsOneWidget);
    expect(find.text('Fan repair'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('৳1,130'), findsOneWidget);
    expect(find.text('Refreshes every 30 seconds'), findsOneWidget);

    await choose(tester, h, 'Status: Any', 'On the way');
    expect(_query(h)['status'], 'on_the_way');

    await tester.enterText(find.byType(TextField), 'Banani ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle(tester);
    expect(_query(h), containsPair('area', 'Banani'));

    await tester.tap(find.text('Any date'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, '10/01/2026');
    await tester.enterText(fields.last, '10/05/2026');
    await tester.tap(find.text('OK'));
    await h.settle(tester);
    expect(_query(h), containsPair('from', '2026-10-01'));
    expect(_query(h), containsPair('to', '2026-10-05'));
    expect(_query(h), containsPair('status', 'on_the_way'));
    expect(find.text('1 Oct 2026 – 5 Oct 2026'), findsOneWidget);

    await tester.tap(find.text('1 Oct 2026 – 5 Oct 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(_query(h), containsPair('from', '2026-10-01'));

    await tester.tap(find.byTooltip('Clear dates'));
    await h.settle(tester);
    expect(_query(h).containsKey('from'), isFalse);
    expect(find.text('Any date'), findsOneWidget);

    await tester.tap(find.text('PAO-104233'));
    await h.settle(tester);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });

  testWidgets('the monitor reloads on its own while open', (tester) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester);
    _reply(h, <Map<String, Object?>>[]);
    await h.pumpApp(tester, Routes.bookings);
    expect(find.text('No bookings match these filters.'), findsOneWidget);
    _reply(h, [bookingSummary(status: 'in_progress')]);
    await tester.pump(const Duration(seconds: 30));
    await h.settle(tester);
    expect(find.text('In progress'), findsOneWidget);
    expect(h.sent.where((o) => o.path == _list), hasLength(2));
  });

  testWidgets('a failed refresh keeps the rows; a failed load retries', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_list, (s) => s.reply(500, apiError('INTERNAL')));
    await h.pumpApp(tester, Routes.bookings);
    expect(find.text('Try again'), findsOneWidget);
    _reply(h, [bookingSummary(status: 'requested')]);
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Requested'), findsOneWidget);
    h.http.onGet(_list, (s) => s.reply(500, apiError('INTERNAL')));
    await tester.pump(const Duration(seconds: 30));
    await h.settle(tester);
    expect(find.text('Requested'), findsOneWidget);
  });
}
