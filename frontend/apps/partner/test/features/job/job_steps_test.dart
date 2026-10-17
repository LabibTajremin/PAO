import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/features/home/presentation/home_page.dart';
import 'package:pao_partner/features/job/presentation/live_job_page.dart';
import 'package:pao_partner/features/job/presentation/rate_customer_page.dart';
import 'package:pao_ui/pao_ui.dart';

import 'job_fixtures.dart';

const _job = '/v1/provider/jobs/b1';

void main() {
  testWidgets('extras: pick published items and send them for approval', (
    tester,
  ) async {
    final h = await openJob(tester, booking(status: 'in_progress'), 'extras');
    expect(find.text('Something went wrong'), findsOneWidget);
    h.http.onGet(
      '/v1/provider/catalog',
      (s) => s.reply(
        200,
        catalog([subService('a'), subService('z', published: false)]),
      ),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Capacitor a'), findsOneWidget);
    expect(find.text('Capacitor z'), findsNothing);
    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    h.http.onPost(
      '$_job/extras',
      (s) => s.reply(409, apiError('EXTRAS_PENDING')),
    );
    await tester.tap(find.text('Send to customer · ৳500'));
    await h.settle(tester);
    expect(
      find.text('Extra items are waiting for the customer.'),
      findsOneWidget,
    );
    h.http.onPost(
      '$_job/extras',
      (s) => s.reply(
        200,
        booking(status: 'in_progress', pendingExtras: proposal('pending')),
      ),
    );
    await tester.tap(find.text('Send to customer · ৳500'));
    await h.settle(tester);
    expect(h.bodyOf('$_job/extras'), {
      'items': [
        {'subServiceId': 'a', 'quantity': 1},
      ],
    });
    expect(find.text('Waiting for the customer'), findsOneWidget);
    h.http.onGet(_job, (s) => s.reply(200, booking(status: 'in_progress')));
    await tester.tap(find.text('Back to job'));
    await h.settle(tester);
    expect(find.byType(LiveJobPage), findsOneWidget);
  });

  testWidgets('extras: the last decision is shown above the picker', (
    tester,
  ) async {
    final h = await openJob(
      tester,
      booking(status: 'in_progress', pendingExtras: proposal('declined')),
    );
    h.http.onGet(
      '/v1/provider/catalog',
      (s) => s.reply(200, catalog([subService('a')])),
    );
    await h.go(tester, '/jobs/b1/extras');
    expect(
      find.text('The customer declined the last extra items.'),
      findsOneWidget,
    );
    h.http.onGet(
      _job,
      (s) => s.reply(
        200,
        booking(status: 'in_progress', pendingExtras: proposal('approved')),
      ),
    );
    await h.go(tester, '/home');
    await h.go(tester, '/jobs/b1/extras');
    expect(
      find.text('The customer approved the last extra items.'),
      findsOneWidget,
    );
  });

  testWidgets('complete: cash must be confirmed, then rating opens', (
    tester,
  ) async {
    final h = await openJob(tester, booking(status: 'in_progress'), 'complete');
    expect(find.text('I received ৳800 in cash'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaoButton, 'Complete job'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.path == '$_job/complete'), isEmpty);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    h.http.onPost(
      '$_job/complete',
      (s) => s.reply(422, apiError('CASH_CONFIRMATION_REQUIRED')),
    );
    await tester.tap(find.widgetWithText(PaoButton, 'Complete job'));
    await h.settle(tester);
    expect(find.text('Confirm that you received the cash.'), findsOneWidget);
    h.http.onPost(
      '$_job/complete',
      (s) => s.reply(200, booking(status: 'completed')),
    );
    await tester.tap(find.widgetWithText(PaoButton, 'Complete job'));
    await h.settle(tester);
    expect(h.bodyOf('$_job/complete'), {'cashReceived': true});
    expect(find.byType(RateCustomerPage), findsOneWidget);
  });

  testWidgets('rate: stars, tags and a comment, then home', (tester) async {
    final h = await openJob(tester, booking(status: 'completed'), 'rate');
    expect(find.text('How was this customer?'), findsOneWidget);
    h.http.onPost(
      '$_job/review',
      (s) => s.reply(409, apiError('REVIEW_ALREADY_SUBMITTED')),
    );
    await tester.tap(find.text('Submit rating'));
    await h.settle(tester);
    expect(h.sent.where((o) => o.path == '$_job/review'), isEmpty);
    await tester.tap(find.byTooltip('4'));
    await tester.tap(find.text('Polite'));
    await tester.tap(find.text('Paid promptly'));
    await tester.tap(find.text('Paid promptly'));
    await tester.enterText(find.byType(TextField), 'Clear directions');
    await tester.pump();
    await tester.tap(find.text('Submit rating'));
    await h.settle(tester);
    expect(find.text('You have already rated this job.'), findsOneWidget);
    h.http.onPost(
      '$_job/review',
      (s) => s.reply(201, {
        'id': 'r1',
        'bookingId': 'b1',
        'stars': 4,
        'tags': ['polite'],
        'authorName': 'Karim',
        'createdAt': '2026-10-09T05:00:00Z',
      }),
    );
    await tester.tap(find.text('Submit rating'));
    await h.settle(tester);
    expect(h.bodyOf('$_job/review'), {
      'stars': 4,
      'tags': ['polite'],
      'comment': 'Clear directions',
    });
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('rate: every tag is labelled and skipping goes home', (
    tester,
  ) async {
    final h = await openJob(tester, booking(status: 'completed'), 'rate');
    for (final label in [
      'Clear instructions',
      'Safe place',
      'Rude',
      'Unclear instructions',
      'Unsafe place',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Skip'));
    await h.settle(tester);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
