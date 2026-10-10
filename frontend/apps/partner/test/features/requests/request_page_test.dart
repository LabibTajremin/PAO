import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/home/presentation/home_page.dart';
import 'package:pao_partner/features/job/presentation/live_job_page.dart';

import '../../support/harness.dart';
import '../job/job_fixtures.dart';

const _job = '/v1/provider/jobs/b1';

// The harness clock reads 04:00:00Z; this deadline leaves two minutes.
const _deadline = '2026-10-09T04:02:00Z';

Future<Harness> _open(WidgetTester tester, Map<String, Object?> json) async {
  tallScreen(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http.onGet(_job, (s) => s.reply(200, json));
  await h.pumpApp(tester, Routes.requestOf('b1'));
  return h;
}

Map<String, Object?> _request({String? deadline = _deadline}) => booking(
  status: 'requested',
  deadline: deadline,
  party: null,
  located: false,
  distanceM: 1240,
  note: 'Second floor',
);

void main() {
  testWidgets('shows the request and counts down', (tester) async {
    await _open(tester, _request());
    expect(find.text('Fan repair'), findsOneWidget);
    expect(find.text('As soon as possible'), findsOneWidget);
    expect(find.text('Banani'), findsOneWidget);
    expect(find.text('1.2 km away'), findsOneWidget);
    expect(find.text('Second floor'), findsOneWidget);
    expect(find.text('৳800'), findsOneWidget);
    expect(find.text('2:00 left to answer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1:59 left to answer'), findsOneWidget);
  });

  testWidgets('accepting opens the live job', (tester) async {
    final h = await _open(tester, _request());
    h.http.onPost(
      '$_job/accept',
      (s) => s.reply(409, apiError('ACTIVE_JOB_EXISTS')),
    );
    await tester.tap(find.text('Accept'));
    await h.settle(tester);
    expect(find.text('Finish your current job first.'), findsOneWidget);
    h.http
      ..onPost('$_job/accept', (s) => s.reply(200, booking()))
      ..onGet(_job, (s) => s.reply(200, booking()));
    await tester.tap(find.text('Accept'));
    await h.settle(tester);
    expect(find.byType(LiveJobPage), findsOneWidget);
  });

  testWidgets('rejecting asks for a reason, then returns home', (tester) async {
    final h = await _open(tester, _request());
    await tester.tap(find.text('Reject'));
    await h.settle(tester);
    expect(find.text('Why are you rejecting?'), findsOneWidget);
    for (final reason in ['I am busy', 'Not my service', 'Other reason']) {
      expect(find.text(reason), findsOneWidget);
    }
    await tester.tap(find.text('Too far away'));
    await tester.pump();
    h.http.onPost(
      '$_job/reject',
      (s) => s.reply(200, booking(status: 'rejected')),
    );
    await tester.tap(find.text('Reject').last);
    await h.settle(tester);
    expect(h.bodyOf('$_job/reject'), {'reason': 'too_far'});
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('the request expires when the countdown ends', (tester) async {
    final h = await _open(tester, _request(deadline: '2026-10-09T04:00:02Z'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('This request is no longer open'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('an answer from another device shows the expired state', (
    tester,
  ) async {
    final h = await _open(tester, _request());
    h.http.onPost(
      '$_job/accept',
      (s) => s.reply(409, apiError('BOOKING_ALREADY_RESPONDED')),
    );
    await tester.tap(find.text('Accept'));
    await h.settle(tester);
    expect(
      find.text('The time to answer passed or it was already answered.'),
      findsOneWidget,
    );
  });

  testWidgets('scheduled requests show their time', (tester) async {
    await _open(
      tester,
      booking(
        status: 'requested',
        timing: 'scheduled',
        scheduledAt: '2026-10-10T04:30:00Z',
      ),
    );
    expect(find.text('Scheduled for 10 Oct, 10:30 AM'), findsOneWidget);
    expect(find.textContaining('left to answer'), findsNothing);
  });

  testWidgets('a failed load can be retried', (tester) async {
    tallScreen(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http.onGet(_job, (s) => s.reply(503, apiError('INTERNAL')));
    await h.pumpApp(tester, Routes.requestOf('b1'));
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsOneWidget,
    );
    h.http.onGet(_job, (s) => s.reply(200, _request()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
