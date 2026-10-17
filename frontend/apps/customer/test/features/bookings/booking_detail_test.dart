import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/booking/presentation/waiting_page.dart';
import 'package:pao_customer/features/bookings/presentation/receipt_page.dart';
import 'package:pao_customer/features/live/presentation/live_page.dart';
import 'package:pao_customer/features/rating/presentation/rating_page.dart';
import 'package:pao_customer/features/report/presentation/report_page.dart';
import 'package:pao_customer/features/service/presentation/service_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _list = '/v1/customer/bookings';
var _n = 0;

Future<Harness> _start(WidgetTester tester) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  await h.pumpApp(tester);
  return h;
}

/// Opens the detail of a booking the API answers with [json].
Future<void> _open(
  WidgetTester tester,
  Harness h,
  Map<String, Object?> json,
) async {
  final id = 'b${_n++}';
  h.http.onGet('$_list/$id', (s) => s.reply(200, json));
  await h.go(tester, Routes.booking(id));
  // Replacing one detail with another rebuilds before the request starts.
  await h.settle(tester);
}

Future<void> _tapAndBack(WidgetTester tester, Harness h, String label) async {
  await tester.tap(find.text(label));
  await h.settle(tester);
}

void main() {
  testWidgets('a live booking shows provider, timeline, bill and actions', (
    tester,
  ) async {
    final h = await _start(tester);
    await _open(tester, h, booking(note: 'Gate code 1234'));
    expect(find.text('Booking details'), findsOneWidget);
    expect(find.text('PAO-104233'), findsOneWidget);
    expect(find.text('4.8 rating · 132 reviews'), findsOneWidget);
    expect(find.text('House 12, Road 5, Banani'), findsOneWidget);
    expect(find.text('Gate code 1234'), findsOneWidget);
    expect(find.text('Accepted · 9 Oct, 10:00 AM'), findsOneWidget);
    expect(find.text('Regulator × 2'), findsOneWidget);
    expect(find.text('Added during the job'), findsOneWidget);
    expect(find.text('৳2,000'), findsOneWidget);
    expect(
      find.text('Pay the provider in cash when the job is done.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Call provider'));
    expect(h.launched.single.toString(), 'tel:+8801711111111');
    await _tapAndBack(tester, h, 'Track live');
    expect(find.byType(LivePage), findsOneWidget);
    await _open(tester, h, booking());
    await _tapAndBack(tester, h, 'Report a problem');
    expect(find.byType(ReportPage), findsOneWidget);
  });

  testWidgets('a request waits; completed bookings rate and show receipts', (
    tester,
  ) async {
    final h = await _start(tester);
    await _open(
      tester,
      h,
      booking(status: 'requested', provider: null, timeline: []),
    );
    expect(find.text('Report a problem'), findsNothing);
    expect(find.text('Timeline'), findsNothing);
    await _tapAndBack(tester, h, 'See request status');
    expect(find.byType(WaitingPage), findsOneWidget);
    await _open(tester, h, booking(status: 'completed'));
    expect(find.text('Paid in cash'), findsOneWidget);
    expect(find.byTooltip('Call provider'), findsNothing);
    await _tapAndBack(tester, h, 'Rate provider');
    expect(find.byType(RatingPage), findsOneWidget);
    await _open(
      tester,
      h,
      booking(status: 'completed', reviewed: true, provider: {'rating': null}),
    );
    expect(find.text('Rate provider'), findsNothing);
    expect(find.textContaining('rating'), findsNothing);
    await _tapAndBack(tester, h, 'View receipt');
    expect(find.byType(ReceiptPage), findsOneWidget);
  });

  testWidgets('ended bookings explain who stopped them and why (C57)', (
    tester,
  ) async {
    final h = await _start(tester);
    final cases = {
      booking(
        status: 'cancelled',
        timeline: [
          step('cancelled', actor: 'customer', reason: 'changed_mind'),
        ],
      ): [
        'This booking was cancelled',
        'You cancelled it.',
        'Reason: Changed my mind',
      ],
      booking(
        status: 'cancelled',
        timeline: [step('cancelled', actor: 'provider', reason: 'flooded')],
      ): [
        'The provider cancelled it.',
        'Reason: flooded',
      ],
      booking(
        status: 'cancelled',
        timeline: [step('cancelled', actor: 'admin', reason: '')],
      ): [
        'PAO cancelled it.',
      ],
      booking(status: 'cancelled', timeline: []): [
        'This booking was cancelled',
      ],
      booking(
        status: 'rejected',
        timeline: [step('rejected', actor: 'provider', reason: 'busy')],
      ): [
        'The provider declined this booking',
        'Reason: Provider was busy',
      ],
      booking(status: 'timed_out', provider: null): [
        'The provider did not answer in time',
      ],
    };
    for (final MapEntry(key: json, value: lines) in cases.entries) {
      await _open(tester, h, json);
      for (final line in [...lines, 'You were not charged.']) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
    }
    await _tapAndBack(tester, h, 'Book again');
    expect(find.byType(ServicePage), findsOneWidget);
  });

  testWidgets('a failed load retries; pulling refreshes', (tester) async {
    final h = await _start(tester);
    h.http.onGet('$_list/x', (s) => s.reply(404, apiError('NOT_FOUND')));
    await h.go(tester, Routes.booking('x'));
    expect(find.byType(PaoErrorState), findsOneWidget);
    h.http.onGet('$_list/x', (s) => s.reply(200, booking()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Accepted'), findsWidgets);
    h.http.onGet('$_list/x', (s) => s.reply(200, booking(status: 'arrived')));
    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await h.settle(tester);
    expect(find.text('Arrived'), findsWidgets);
  });
}
