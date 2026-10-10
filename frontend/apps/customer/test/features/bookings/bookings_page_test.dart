import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _list = '/v1/customer/bookings';

Future<Harness> _start(WidgetTester tester) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  return h;
}

void main() {
  testWidgets('upcoming bookings page through "load more"; past is empty', (
    tester,
  ) async {
    final h = await _start(tester);
    h.http.onGet(
      _list,
      (s) => s.replyCallback(200, (o) {
        if (o.queryParameters['tab'] == 'past') return {'items': <Object?>[]};
        return o.queryParameters['cursor'] == null
            ? {
                'items': [summary()],
                'nextCursor': 'c2',
              }
            : {
                'items': [
                  summary(id: 'b2', status: 'requested', provider: null),
                ],
              };
      }),
    );
    await h.pumpApp(tester, Routes.bookings);
    expect(find.text('My bookings'), findsOneWidget);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('9 Oct 2026, 10:00 AM'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('৳1,130'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Waiting for reply'), findsOneWidget);
    await tester.tap(find.text('Past'));
    await h.settle(tester);
    expect(find.text('No past bookings yet'), findsOneWidget);
    await tester.tap(find.text('Upcoming'));
    await h.settle(tester);
    h.http.onGet('$_list/$bookingId', (s) => s.reply(200, booking()));
    await tester.tap(find.text('Fan repair').first);
    await h.settle(tester);
    expect(find.byType(BookingDetailPage), findsOneWidget);
  });

  testWidgets('no upcoming bookings sends the customer home to book', (
    tester,
  ) async {
    final h = await _start(tester);
    h.http.onGet(_list, (s) => s.reply(200, {'items': <Object?>[]}));
    await h.pumpApp(tester, Routes.bookings);
    expect(find.text('No upcoming bookings'), findsOneWidget);
    await tester.tap(find.text('Book a service'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
  });

  testWidgets('a failed list retries and pulls to refresh', (tester) async {
    final h = await _start(tester);
    h.http.onGet(_list, (s) => s.reply(503, apiError('INTERNAL')));
    await h.pumpApp(tester, Routes.bookings);
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsOneWidget,
    );
    h.http.onGet(
      _list,
      (s) => s.reply(200, {
        'items': [summary(status: 'completed')],
      }),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Completed'), findsOneWidget);
    h.http.onGet(
      _list,
      (s) => s.reply(200, {
        'items': [summary(status: 'cancelled')],
      }),
    );
    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await h.settle(tester);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.byType(PaoBadge), findsOneWidget);
  });
}
