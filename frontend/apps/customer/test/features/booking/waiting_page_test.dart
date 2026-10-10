import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/features/booking/presentation/confirmed_page.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_page.dart';
import 'package:pao_customer/features/connectivity/presentation/stale_notice.dart';
import 'package:pao_customer/features/live/presentation/live_page.dart';

import '../../support/harness.dart';
import 'booking_fixtures.dart';

// The harness clock reads 04:00:00Z; this deadline leaves two minutes.
const _deadline = '2026-10-09T04:02:00Z';

Map<String, Object?> _requested({String deadline = _deadline}) => booking(
  status: 'requested',
  deadline: deadline,
  provider: party(phone: null),
);

Uri _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri;

void main() {
  testWidgets('counts down and opens the live booking once accepted', (
    tester,
  ) async {
    final h = await openBooking(tester, _requested(), 'waiting');
    expect(find.text('Waiting for Rahim Uddin to accept'), findsOneWidget);
    expect(find.text('2:00'), findsOneWidget);
    expect(find.text('৳1,300'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1:59'), findsOneWidget);
    h.http
      ..onGet(bookingPath, (s) => s.reply(500, apiError('INTERNAL')))
      ..onGet('$bookingPath/start-code', (s) => s.reply(200, {'code': '4821'}));
    await tester.pump(const Duration(seconds: 4));
    await h.settle(tester);
    expect(find.byType(StaleNotice), findsOneWidget);
    h.http.onGet(bookingPath, (s) => s.reply(200, booking()));
    await tester.pump(const Duration(seconds: 5));
    await h.settle(tester);
    expect(find.byType(LivePage), findsOneWidget);
  });

  testWidgets('an accepted scheduled booking is confirmed for later', (
    tester,
  ) async {
    final h = await openBooking(
      tester,
      booking(timing: 'scheduled', scheduledAt: '2026-10-10T04:00:00Z'),
      'waiting',
    );
    expect(find.byType(ConfirmedPage), findsOneWidget);
    expect(find.text('Saturday 10 October 2026, 10:00 AM'), findsOneWidget);
    expect(find.text('Item x2 × 1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.call_outlined));
    await tester.tap(find.text('View booking'));
    await h.settle(tester);
    expect(h.launched.single.toString(), 'tel:01711111111');
    expect(find.text('C19'), findsOneWidget);
    await h.go(tester, '/bookings/b1/confirmed');
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
  });

  testWidgets('a declined request sends the customer back to the list', (
    tester,
  ) async {
    final h = await openBooking(
      tester,
      booking(status: 'rejected', provider: party(phone: null)),
      'waiting',
    );
    expect(find.text("Rahim Uddin can't take this job"), findsOneWidget);
    await tester.tap(find.text('Choose another provider'));
    await tester.pumpAndSettle();
    expect(find.text('C10'), findsOneWidget);
    expect(_location(tester).queryParameters, {
      'service': 's1',
      'items': 'x1:2',
    });
    await h.go(tester, '/bookings/b1/waiting');
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
  });

  testWidgets('a hire that ran out of time keeps its start', (tester) async {
    final h = await openBooking(
      tester,
      booking(
        status: 'requested',
        deadline: '2026-10-09T04:00:02Z',
        model: 'duration_hire',
        timing: 'scheduled',
        scheduledAt: '2026-10-10T02:00:00Z',
      ),
      'waiting',
    );
    await tester.pump(const Duration(seconds: 2));
    await h.settle(tester);
    expect(find.text('No answer in time'), findsOneWidget);
    await tester.tap(find.text('Choose another provider'));
    await tester.pumpAndSettle();
    expect(_location(tester).queryParameters['at'], '2026-10-10T02:00:00.000Z');
    await h.go(tester, '/bookings/b1/waiting');
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
  });

  testWidgets('the request can be cancelled; a cancelled one goes home', (
    tester,
  ) async {
    final h = await openBooking(tester, _requested(), 'waiting');
    await tester.tap(find.text('Cancel request'));
    await h.settle(tester);
    expect(find.byType(CancelPage), findsOneWidget);
    h.http.onGet(
      bookingPath,
      (s) => s.reply(200, booking(status: 'cancelled')),
    );
    await tester.tap(find.text('Keep booking'));
    await h.settle(tester);
    expect(find.text('Booking cancelled'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
  });

  testWidgets('a failed load can be retried; home is one tap away', (
    tester,
  ) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http.onGet(bookingPath, (s) => s.reply(404, apiError('NOT_FOUND')));
    await h.pumpApp(tester, '/bookings/b1/waiting');
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(bookingPath, (s) => s.reply(200, _requested()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
  });

  testWidgets('a completed booking moves on from waiting', (tester) async {
    final h = await openBooking(
      tester,
      booking(status: 'completed'),
      'waiting',
    );
    await h.settle(tester);
    expect(find.text('All done!'), findsOneWidget);
  });
}
