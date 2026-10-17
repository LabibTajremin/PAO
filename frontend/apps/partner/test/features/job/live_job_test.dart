import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/home/presentation/home_page.dart';
import 'package:pao_partner/features/job/presentation/complete_page.dart';
import 'package:pao_partner/features/job/presentation/extras_page.dart';
import 'package:pao_partner/features/job/presentation/live_job_page.dart';
import 'package:pao_partner/features/job/presentation/rate_customer_page.dart';
import 'package:pao_partner/features/job/presentation/start_code_page.dart';
import 'package:pao_partner/features/requests/presentation/request_page.dart';

import '../../support/harness.dart';
import 'job_fixtures.dart';

const _job = '/v1/provider/jobs/b1';

void main() {
  testWidgets('an accepted job hands off to maps and the dialler, then moves '
      'on the way', (tester) async {
    final h = await openJob(tester, booking());
    expect(find.text('Nusrat Jahan'), findsOneWidget);
    expect(find.text('House 12, Road 5, Banani'), findsOneWidget);
    await tester.tap(find.text('Directions'));
    await tester.tap(find.text('Call'));
    await h.settle(tester);
    expect(h.launched.first.queryParameters['destination'], '23.79,90.4');
    expect(h.launched.last.toString(), 'tel:01711111111');
    h.http.onPost(
      '$_job/on-the-way',
      (s) => s.reply(200, booking(status: 'on_the_way')),
    );
    await tester.tap(find.text("I'm on the way"));
    await h.settle(tester);
    h.http.onPost(
      '$_job/arrived',
      (s) => s.reply(409, apiError('BOOKING_INVALID_TRANSITION')),
    );
    await tester.tap(find.text("I've arrived"));
    await h.settle(tester);
    expect(
      find.text('This booking cannot change that way now.'),
      findsOneWidget,
    );
  });

  testWidgets('arrived opens the start code; a right code returns to the '
      'started job', (tester) async {
    final h = await openJob(tester, booking(status: 'arrived', party: null));
    expect(find.text('Call'), findsNothing);
    await tester.tap(find.text('Enter start code'));
    await h.settle(tester);
    expect(find.byType(StartCodePage), findsOneWidget);
    h.http.onPost(
      '$_job/start',
      (s) => s.reply(422, apiError('START_CODE_INVALID')),
    );
    await tester.enterText(find.byType(TextField), '0000');
    await h.settle(tester);
    expect(find.text('That start code is not right.'), findsOneWidget);
    h.http
      ..onPost(
        '$_job/start',
        (s) => s.reply(200, booking(status: 'in_progress')),
      )
      ..onGet(_job, (s) => s.reply(200, booking(status: 'in_progress')));
    await tester.enterText(find.byType(TextField), '4821');
    await h.settle(tester);
    expect(h.bodyOf('$_job/start'), {'code': '4821'});
    expect(find.byType(LiveJobPage), findsOneWidget);
    expect(find.text('Complete job'), findsOneWidget);
    expect(find.text('Add extra items'), findsOneWidget);
  });

  testWidgets('too many wrong codes lock the entry', (tester) async {
    final h = await openJob(tester, booking(status: 'arrived'), 'start');
    h.http.onPost(
      '$_job/start',
      (s) => s.reply(429, apiError('START_CODE_LOCKED')),
    );
    await tester.enterText(find.byType(TextField), '1111');
    await h.settle(tester);
    expect(
      find.text('Too many wrong codes. Try again in a few minutes.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('cancelling asks for a reason and returns home', (tester) async {
    final h = await openJob(tester, booking(status: 'on_the_way'));
    await tester.tap(find.text('Cancel job'));
    await h.settle(tester);
    expect(
      find.text('Cancelling after accepting lowers your ranking.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Emergency'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Flat tyre');
    h.http.onPost(
      '$_job/cancel',
      (s) => s.reply(200, booking(status: 'cancelled')),
    );
    await tester.tap(find.text('Cancel job').last);
    await h.settle(tester);
    expect(h.bodyOf('$_job/cancel'), {
      'reason': 'emergency',
      'note': 'Flat tyre',
    });
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('a dismissed cancel sheet sends nothing', (tester) async {
    final h = await openJob(tester, booking());
    await tester.tap(find.text('Cancel job'));
    await h.settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await h.settle(tester);
    expect(h.sent.where((o) => o.path == '$_job/cancel'), isEmpty);
  });

  testWidgets('a job the customer cancelled says so', (tester) async {
    final h = await openJob(
      tester,
      booking(
        status: 'cancelled',
        timeline: [
          {
            'status': 'cancelled',
            'at': '2026-10-09T04:00:00Z',
            'actor': 'customer',
          },
        ],
      ),
    );
    expect(find.text('This job was cancelled'), findsOneWidget);
    expect(find.text('The customer cancelled this job.'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('other closed jobs explain themselves', (tester) async {
    final h = await openJob(
      tester,
      booking(
        status: 'cancelled',
        timeline: [
          {
            'status': 'cancelled',
            'at': '2026-10-09T04:00:00Z',
            'actor': 'admin',
          },
        ],
      ),
    );
    expect(find.text('It can no longer be worked on.'), findsOneWidget);
    h.http.onGet(_job, (s) => s.reply(200, booking(status: 'timed_out')));
    await h.go(tester, Routes.home);
    await h.go(tester, Routes.job('b1', 'live'));
    expect(find.text('This job is no longer active'), findsOneWidget);
  });

  testWidgets('a started job opens extras and completion, and shows a '
      'pending proposal', (tester) async {
    final h = await openJob(
      tester,
      booking(status: 'in_progress', pendingExtras: proposal('pending')),
    );
    expect(
      find.text('The customer is asked to approve ৳500 of extra items.'),
      findsOneWidget,
    );
    h.http.onGet('/v1/provider/catalog', (s) => s.reply(200, catalog([])));
    await tester.tap(find.text('Add extra items'));
    await h.settle(tester);
    expect(find.byType(ExtrasPage), findsOneWidget);
    await tester.tap(find.text('Back to job'));
    await h.settle(tester);
    await tester.tap(find.text('Complete job'));
    await h.settle(tester);
    expect(find.byType(CompletePage), findsOneWidget);
  });

  testWidgets('a completed job leads to rating once', (tester) async {
    final h = await openJob(tester, booking(status: 'completed'));
    await tester.tap(find.text('Rate customer'));
    await h.settle(tester);
    expect(find.byType(RateCustomerPage), findsOneWidget);
    h.http.onGet(
      _job,
      (s) => s.reply(200, booking(status: 'completed', reviewedByMe: true)),
    );
    await h.go(tester, Routes.home);
    await h.go(tester, Routes.job('b1', 'live'));
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('a job still requested links to the request', (tester) async {
    final h = await openJob(tester, booking(status: 'requested'));
    await tester.tap(find.text('Open request'));
    await h.settle(tester);
    expect(find.byType(RequestPage), findsOneWidget);
  });

  testWidgets('offline loads show a retry', (tester) async {
    tallScreen(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http.onGet(
      _job,
      (s) => s.throws(
        0,
        DioException.connectionError(
          requestOptions: RequestOptions(path: _job),
          reason: 'offline',
        ),
      ),
    );
    await h.pumpApp(tester, Routes.job('b1', 'live'));
    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );
    h.http.onGet(_job, (s) => s.reply(200, booking()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text("I'm on the way"), findsOneWidget);
  });
}
