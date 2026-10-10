import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/job/presentation/live_job_page.dart';
import 'package:pao_partner/features/jobs/presentation/job_detail_page.dart';
import 'package:pao_partner/features/jobs/presentation/report_page.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

void main() {
  Future<Harness> start(WidgetTester tester) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    return h;
  }

  testWidgets('upcoming jobs page through "load more"; past can be empty', (
    tester,
  ) async {
    final h = await start(tester);
    h.http.onGet(
      '/v1/provider/jobs',
      (s) => s.replyCallback(200, (o) {
        if (o.queryParameters['tab'] == 'past') return {'items': <Object?>[]};
        return o.queryParameters['cursor'] == null
            ? {
                'items': [summary()],
                'nextCursor': 'c2',
              }
            : {
                'items': [
                  summary(id: 'b2', status: 'completed', customer: null),
                ],
              };
      }),
    );
    await h.pumpApp(tester, Routes.jobs);
    expect(find.text('Fan repair'), findsOneWidget);
    expect(find.textContaining('Nusrat · 9 Oct'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
    await tester.tap(find.text('Past'));
    await h.settle(tester);
    expect(find.text('No past jobs yet'), findsOneWidget);
    await tester.tap(find.text('Upcoming'));
    await h.settle(tester);
    await tester.tap(find.text('Fan repair').first);
    await h.settle(tester);
    expect(find.byType(JobDetailPage), findsOneWidget);
  });

  testWidgets('jobs show a retryable error, also when more fails', (
    tester,
  ) async {
    final h = await start(tester);
    h.http.onGet(
      '/v1/provider/jobs',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await h.pumpApp(tester, Routes.jobs);
    expect(find.text('Our service had a problem. Please try again.'), findsOne);
    h.http.onGet(
      '/v1/provider/jobs',
      (s) => s.reply(200, {
        'items': [summary()],
        'nextCursor': 'c2',
      }),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Fan repair'), findsOneWidget);
    h.http.onGet(
      '/v1/provider/jobs',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Our service had a problem. Please try again.'), findsOne);
    expect(find.text('Load more'), findsOneWidget);
    await tester.tap(find.text('Upcoming'));
    await h.settle(tester);
  });

  testWidgets('an active job shows items, timeline and opens the live job', (
    tester,
  ) async {
    final h = await start(tester);
    h.http.onGet(
      '/v1/provider/jobs/$bookingId',
      (s) => s.reply(200, booking()),
    );
    await h.pumpApp(tester, Routes.job(bookingId));
    expect(find.text('Customer: Nusrat'), findsOneWidget);
    expect(find.text('Area: Banani'), findsOneWidget);
    expect(find.text('Ceiling fan × 2'), findsOneWidget);
    expect(find.text('Added during the job'), findsOneWidget);
    expect(find.text('৳1,130'), findsOneWidget);
    expect(find.textContaining('Requested · 9 Oct'), findsOneWidget);
    expect(find.text('View receipt'), findsNothing);
    await tester.tap(find.text('Continue job'));
    await h.settle(tester);
    expect(find.byType(LiveJobPage), findsOneWidget);
  });

  testWidgets('a completed job shows its receipt and links to a report', (
    tester,
  ) async {
    final h = await start(tester);
    h.http
      ..onGet(
        '/v1/provider/jobs/$bookingId',
        (s) => s.reply(200, booking(status: 'completed', customer: false)),
      )
      ..onGet(
        '/v1/provider/jobs/$bookingId/receipt',
        (s) => s.reply(404, apiError('NOT_FOUND')),
      );
    await h.pumpApp(tester, Routes.job(bookingId));
    expect(find.textContaining('Customer:'), findsNothing);
    expect(find.text('Continue job'), findsNothing);
    await tester.tap(find.text('View receipt'));
    await h.settle(tester);
    expect(find.text('We could not find that.'), findsOneWidget);
    h.http.onGet(
      '/v1/provider/jobs/$bookingId/receipt',
      (s) => s.reply(200, receipt()),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Paid in cash'), findsOneWidget);
    expect(find.text('Customer: Nusrat'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await h.settle(tester);
    await tester.tap(find.text('Report a problem'));
    await h.settle(tester);
    expect(find.byType(ReportPage), findsOneWidget);
  });

  testWidgets('job detail without a timeline, then a load failure', (
    tester,
  ) async {
    final h = await start(tester);
    h.http.onGet(
      '/v1/provider/jobs/$bookingId',
      (s) => s.reply(200, {
        ...booking(status: 'cancelled'),
        'timeline': <Object?>[],
      }),
    );
    await h.pumpApp(tester, Routes.job(bookingId));
    expect(find.text('Timeline'), findsNothing);
    expect(find.text('Cancelled'), findsOneWidget);
    h.http.onGet(
      '/v1/provider/jobs/$bookingId',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await h.go(tester, Routes.jobs);
    await h.go(tester, Routes.job(bookingId));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
