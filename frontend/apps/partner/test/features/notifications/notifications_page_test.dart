import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/job/presentation/live_job_page.dart';
import 'package:pao_partner/features/notifications/presentation/notifications_page.dart';

import '../../support/harness.dart';
import '../job/job_fixtures.dart';

const _inbox = '/v1/provider/notifications';

Map<String, Object?> _note(
  String id, {
  bool read = false,
  String? bookingId,
  String type = 'booking_cancelled',
}) => {
  'id': id,
  'type': type,
  'title': 'Title $id',
  'body': 'Body $id',
  'bookingId': ?bookingId,
  'read': read,
  'createdAt': '2026-10-09T03:00:00Z',
};

Future<Harness> _open(
  WidgetTester tester,
  List<Map<String, Object?>> items, {
  int unread = 0,
}) async {
  tallScreen(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http.onGet(
    _inbox,
    (s) => s.reply(200, {'items': items, 'unreadCount': unread}),
  );
  await h.pumpApp(tester, Routes.notifications);
  return h;
}

int _count(Harness h, String path) =>
    h.sent.where((o) => o.path == path).length;

void main() {
  testWidgets('lists notifications and marks them all read', (tester) async {
    final h = await _open(tester, [
      _note('n1'),
      _note('n2', read: true),
    ], unread: 1);
    expect(find.text('Title n1'), findsOneWidget);
    expect(find.text('Body n2\n9 Oct, 9:00 AM'), findsOneWidget);
    h.http
      ..onPost('$_inbox/read-all', (s) => s.reply(204, null))
      ..onGet(
        _inbox,
        (s) => s.reply(200, {
          'items': [_note('n1', read: true)],
          'unreadCount': 0,
        }),
      );
    await tester.tap(find.text('Mark all read'));
    await h.settle(tester);
    expect(_count(h, '$_inbox/read-all'), 1);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('a tap marks it read and opens its job', (tester) async {
    final h = await _open(tester, [
      _note('n1', bookingId: 'b1'),
      _note('n2', read: true, type: 'level_changed_other'),
    ]);
    await tester.tap(find.text('Title n2'));
    await h.settle(tester);
    expect(find.byType(NotificationsPage), findsOneWidget);
    h.http
      ..onPost('$_inbox/n1/read', (s) => s.reply(204, null))
      ..onGet('/v1/provider/jobs/b1', (s) => s.reply(200, booking()));
    await tester.tap(find.text('Title n1'));
    await h.settle(tester);
    expect(_count(h, '$_inbox/n1/read'), 1);
    expect(find.byType(LiveJobPage), findsOneWidget);
  });

  testWidgets('empty, failed and refreshed inboxes', (tester) async {
    final h = await _open(tester, []);
    expect(find.text('No notifications yet'), findsOneWidget);
    h.http.onGet(_inbox, (s) => s.reply(503, apiError('INTERNAL')));
    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await h.settle(tester);
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsOneWidget,
    );
    h.http.onGet(
      _inbox,
      (s) => s.reply(200, {
        'items': [_note('n3')],
        'unreadCount': 1,
      }),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Title n3'), findsOneWidget);
  });
}
