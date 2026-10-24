import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_page.dart';
import 'package:pao_partner/features/home/presentation/home_page.dart';

import '../../support/harness.dart';
import '../enrolment/fakes.dart';

Map<String, Object?> _item(
  String type,
  String status, {
  String? reason,
  String? expires,
}) => {
  'type': type,
  'status': status,
  'required': true,
  'rejectionReason': ?reason,
  'expiresAt': ?expires,
};

Map<String, Object?> _status({
  int level = 1,
  String badge = 'verified',
  List<Object?> items = const [],
  bool cleared = false,
  Map<String, Object?>? level2,
}) => {
  'level': level,
  'badge': badge,
  'items': items,
  'canReceiveBookings': cleared,
  'level2': ?level2,
};

Future<Harness> _open(
  WidgetTester tester,
  Map<String, Object?> status, {
  Set<EnrolStep> done = const {},
  bool submitted = true,
}) async {
  final h = await Harness.create();
  await h.signIn(tester, cleared: false);
  h.http
    ..onGet('/v1/provider/verification', (s) => s.reply(200, status))
    ..onGet(
      '/v1/provider/enrolment',
      (s) => s.reply(200, enrolmentJson(done: done, submitted: submitted)),
    );
  await h.pumpApp(tester, Routes.verification);
  return h;
}

void main() {
  testWidgets('every item shows its status, reason and expiry', (tester) async {
    final h = await _open(
      tester,
      _status(
        badge: 'verified_pro',
        level: 2,
        items: [
          _item('nid', 'rejected', reason: 'Photo is blurred.'),
          _item('police_clearance', 'expired', expires: '2026-09-01T00:00:00Z'),
          _item('selfie', 'approved', expires: '2027-10-01T00:00:00Z'),
          _item('address', 'pending'),
          _item('emergency_contact', 'missing'),
          _item('skill_proof', 'approved'),
          _item('service_area', 'pending'),
          _item('code_of_conduct', 'approved'),
        ],
        level2: {
          'eligible': true,
          'nextSession': {
            'id': 'l1',
            'providerId': 'p1',
            'serviceId': 's1',
            'scheduledAt': '2026-10-20T04:00:00Z',
            'location': 'PAO office, Gulshan 1',
            'status': 'scheduled',
          },
          'retryAfter': '2026-11-01T00:00:00Z',
        },
      ),
      done: allRequired,
    );
    expect(find.text('Level 2'), findsOne);
    expect(find.text('PAO Verified Pro'), findsOne);
    expect(
      find.text('Some items need your attention. Upload them again below.'),
      findsOne,
    );
    for (final text in [
      'Reason: Photo is blurred.',
      'Expired on 1 Sep 2026',
      'Valid until 1 Oct 2027',
      'Rejected',
      'Expired',
      'Missing',
      'Address',
      'Services and area',
    ]) {
      await tester.scrollUntilVisible(find.text(text), 120);
    }
    await tester.scrollUntilVisible(find.text('Code of conduct'), 120);
    expect(
      find.text(
        'Skill check on 20 Oct 2026, 10:00 AM at PAO office, '
        'Gulshan 1',
      ),
      findsOne,
    );
    expect(find.text('You can try again after 1 Nov 2026, 6:00 AM.'), findsOne);
    await tapIn(tester, find.text('Upload again'));
    await h.settle(tester);
    await h.settle(tester);
    expect(find.byType(EnrolmentPage), findsOne);
    expect(find.text('Step 6 of 9'), findsOne);
  });

  testWidgets('missing steps lead back into the wizard', (tester) async {
    final h = await _open(
      tester,
      _status(level: 0, badge: 'none', level2: {'eligible': false}),
      done: {EnrolStep.personal},
      submitted: false,
    );
    expect(find.text('Not verified yet'), findsOne);
    expect(
      find.text('Finish your enrolment so we can check your documents.'),
      findsOne,
    );
    expect(find.text('No documents yet.'), findsOne);
    expect(
      find.text('Reach Level 1 first, then you can take a skill check.'),
      findsOne,
    );
    await tester.tap(find.text('Continue enrolment'));
    await h.settle(tester);
    await h.settle(tester);
    expect(find.byType(EnrolmentPage), findsOne);
  });

  testWidgets('a finished but unsent enrolment goes to the review', (
    tester,
  ) async {
    final h = await _open(
      tester,
      _status(level: 0, badge: 'none'),
      done: allRequired,
      submitted: false,
    );
    await tester.tap(find.text('Review and submit'));
    await h.settle(tester);
    await h.settle(tester);
    await tester.scrollUntilVisible(find.text('Submit for verification'), 120);
  });

  testWidgets('pull to refresh reloads the gate and opens home', (
    tester,
  ) async {
    final h = await _open(tester, _status());
    expect(
      find.text(
        'We are checking your documents. This usually takes up to 48 hours.',
      ),
      findsOne,
    );
    expect(find.text('Go to home'), findsNothing);
    h.http.onGet(
      '/v1/provider/verification',
      (s) => s.reply(200, _status(cleared: true)),
    );
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await h.settle(tester);
    expect(find.text('You are verified and can receive bookings.'), findsOne);
    await tester.tap(find.text('Go to home'));
    await h.settle(tester);
    expect(find.byType(HomePage), findsOne);
  });

  testWidgets('a failed load shows the error and retries', (tester) async {
    final h = await Harness.create();
    await h.signIn(tester, cleared: false);
    h.http.onGet(
      '/v1/provider/verification',
      (s) => s.reply(503, apiError('INTERNAL')),
    );
    await h.pumpApp(tester, Routes.verification);
    expect(find.text('Our service had a problem. Please try again.'), findsOne);
    h.http
      ..onGet('/v1/provider/verification', (s) => s.reply(200, _status()))
      ..onGet(
        '/v1/provider/enrolment',
        (s) => s.reply(200, enrolmentJson(done: allRequired, submitted: true)),
      );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Verified'), findsOne);
  });
}
