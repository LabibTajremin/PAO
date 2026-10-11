import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_l10n/pao_l10n.dart';

import '../../support/harness.dart';

const _path = '/v1/admin/dashboard';

Map<String, Object?> _dashboard({
  List<Map<String, Object?>>? days,
  Map<String, int>? byStatus,
  Map<String, int>? byLevel,
}) => {
  'providersByStatus':
      byStatus ??
      {'pending': 34, 'active': 120, 'suspended': 2, 'banned': 1, 'new': 3},
  'providersByLevel': byLevel ?? {'0': 34, '1': 100, '2': 20, '9': 1},
  'bookingsPerDay':
      days ??
      [
        {'date': '2026-10-07', 'total': 10, 'completed': 8},
        {'date': '2026-10-08', 'total': 0, 'completed': 0},
        {'date': '2026-10-09', 'total': 14, 'completed': 12},
      ],
  'completionRate': 0.86,
  'openComplaints': 5,
  'pendingVerifications': 34,
  'generatedAt': '2026-10-09T04:00:00Z',
};

void main() {
  testWidgets('counts, bookings per day and provider breakdowns', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_path, (s) => s.reply(200, _dashboard()));
    await h.pumpApp(tester);
    expect(find.text('Updated 9 Oct 2026, 10:00 AM'), findsOneWidget);
    expect(find.text('Pending verifications'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('120'), findsNWidgets(2));
    expect(find.text('7 Oct'), findsOneWidget);
    expect(find.text('9 Oct'), findsOneWidget);
    expect(find.byTooltip('9 Oct: 14 bookings, 12 completed'), findsOneWidget);
    for (final label in [
      'Pending',
      'Suspended',
      'Banned',
      'new',
      'Level 0 · Registered',
      'Level 1 · Verified',
      'Level 2 · PAO Verified Pro',
      '9',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.text('Open complaints'));
    await h.settle(tester);
    expect(find.text('A11'), findsOneWidget);
    await h.go(tester, Routes.dashboard);
    await tester.tap(find.text('Pending verifications'));
    await h.settle(tester);
    expect(find.text('A05'), findsOneWidget);
  });

  testWidgets('without queues to open the counts stay put', (tester) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester, screens: ['A02']);
    h.http.onGet(
      _path,
      (s) =>
          s.reply(200, _dashboard(days: [], byStatus: {}, byLevel: {'0': 0})),
    );
    await h.pumpApp(tester);
    expect(find.text('No bookings in this period yet.'), findsOneWidget);
    expect(find.text('No providers yet.'), findsNWidgets(2));
    await tester.tap(find.text('Pending verifications'));
    await h.settle(tester);
    expect(find.text('Pending verifications'), findsOneWidget);
  });

  testWidgets('a failure offers a retry, and refresh reloads', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_path, (s) => s.reply(500, apiError('INTERNAL')));
    await h.pumpApp(tester);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(_path, (s) => s.reply(200, _dashboard()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('86%'), findsOneWidget);
    h.http.onGet(
      _path,
      (s) => s.reply(200, {..._dashboard(), 'completionRate': 0.5}),
    );
    await tester.tap(find.byTooltip('Refresh'));
    await h.settle(tester);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('the dashboard reads in Bangla', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.services.locale.select(PaoLocales.bangla);
    h.http.onGet(_path, (s) => s.reply(200, _dashboard()));
    await h.pumpApp(tester);
    expect(find.text('যাচাইয়ের অপেক্ষায়'), findsOneWidget);
    expect(find.text('৮৬%'), findsOneWidget);
    expect(find.byType(Tooltip), findsWidgets);
  });

  testWidgets('on a phone-sized window the breakdowns stack', (tester) async {
    tester.view
      ..physicalSize = const Size(600, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_path, (s) => s.reply(200, _dashboard()));
    await h.pumpApp(tester);
    final status = tester.getTopLeft(find.text('Providers by status'));
    final level = tester.getTopLeft(find.text('Providers by level'));
    expect(level.dy, greaterThan(status.dy));
  });
}
