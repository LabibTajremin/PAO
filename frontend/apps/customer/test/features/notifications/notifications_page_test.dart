import 'dart:async';

import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_customer/features/notifications/domain/notifications_repository.dart';
import 'package:pao_customer/features/notifications/presentation/notifications_cubit.dart';
import 'package:pao_customer/features/notifications/presentation/notifications_page.dart';

import '../../support/harness.dart';
import '../bookings/fixtures.dart';

const _inbox = '/v1/customer/notifications';

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
  String? next,
}) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http.onGet(
    _inbox,
    (s) => s.reply(200, {
      'items': items,
      'unreadCount': items.where((n) => n['read'] == false).length,
      'nextCursor': ?next,
    }),
  );
  await h.pumpApp(tester, Routes.notifications);
  return h;
}

int _count(Harness h, String path) =>
    h.sent.where((o) => o.path == path).length;

class _Repo implements NotificationsRepository {
  @override
  Future<Paged<Notification>> inbox({String? cursor}) async => Paged([
    Notification(
      id: 'n1',
      type: 't',
      title: 'x',
      body: 'y',
      read: false,
      createdAt: DateTime.utc(2026),
    ),
  ]);

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> registerDevice(String token) async {}
}

void main() {
  test('marking read after closing changes nothing', () async {
    final cubit = NotificationsCubit(_Repo());
    await cubit.load();
    await cubit.close();
    await cubit.markRead('n1');
    expect(cubit.hasUnread, isTrue);
  });

  testWidgets('lists notifications and marks them all read', (tester) async {
    final h = await _open(tester, [_note('n1'), _note('n2', read: true)]);
    expect(find.text('Title n1'), findsOneWidget);
    expect(find.text('Body n2\n9 Oct, 9:00 AM'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Unread')), findsOneWidget);
    h.http.onPost(
      '$_inbox/read-all',
      (s) => s.reply(503, apiError('INTERNAL')),
    );
    await tester.tap(find.text('Mark all read'));
    await h.settle(tester);
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsOneWidget,
    );
    h.http.onPost('$_inbox/read-all', (s) => s.reply(204, null));
    await tester.tap(find.text('Mark all read'));
    await h.settle(tester);
    expect(_count(h, '$_inbox/read-all'), 2);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('a tap marks it read and opens its booking', (tester) async {
    final h = await _open(tester, [
      _note('n1', bookingId: bookingId),
      _note('n2', read: true, type: 'promo'),
      _note('n3'),
    ]);
    await tester.tap(find.text('Title n2'));
    await h.settle(tester);
    expect(find.byType(NotificationsPage), findsOneWidget);
    h.http.onPost(
      '$_inbox/n3/read',
      (s) => s.reply(404, apiError('NOT_FOUND')),
    );
    await tester.tap(find.text('Title n3'));
    await h.settle(tester);
    expect(find.text('Mark all read'), findsOneWidget);
    h.http
      ..onPost('$_inbox/n1/read', (s) => s.reply(204, null))
      ..onGet(
        '/v1/customer/bookings/$bookingId',
        (s) => s.reply(200, booking(status: 'cancelled')),
      );
    await tester.tap(find.text('Title n1'));
    await h.settle(tester);
    expect(_count(h, '$_inbox/n1/read'), 1);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });

  testWidgets('empty, failed, refreshed and paged inboxes', (tester) async {
    final h = await _open(tester, []);
    expect(find.text('No notifications yet'), findsOneWidget);
    h.http.onGet(_inbox, (s) => s.reply(503, apiError('INTERNAL')));
    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await h.settle(tester);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(
      _inbox,
      (s) => s.replyCallback(
        200,
        (o) => {
          'items': [_note(o.queryParameters['cursor'] == null ? 'n3' : 'n4')],
          'unreadCount': 2,
          if (o.queryParameters['cursor'] == null) 'nextCursor': 'c2',
        },
      ),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Title n3'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Title n4'), findsOneWidget);
  });
}
