import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/booking/presentation/waiting_page.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_page.dart';
import 'package:pao_customer/features/connectivity/presentation/stale_notice.dart';
import 'package:pao_customer/features/live/data/secure_screen.dart';
import 'package:pao_customer/features/live/presentation/completed_page.dart';
import 'package:pao_customer/features/live/presentation/extras_page.dart';
import 'package:pao_customer/features/live/presentation/live_page.dart';
import 'package:pao_customer/features/rating/presentation/rating_page.dart';

import '../../support/harness.dart';
import '../booking/booking_fixtures.dart';

const _code = '$bookingPath/start-code';

Future<Harness> _live(
  WidgetTester tester,
  Map<String, Object?> json, {
  bool code = true,
}) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(bookingPath, (s) => s.reply(200, json))
    ..onGet(
      _code,
      (s) => code
          ? s.reply(200, {'code': '4821'})
          : s.reply(409, apiError('CONFLICT')),
    );
  await h.pumpApp(tester, Routes.booking('b1', 'live'));
  return h;
}

List<String> _secureCalls() {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SecureScreen.channel, (call) async {
        calls.add('${call.arguments}');
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SecureScreen.channel, null),
  );
  return calls;
}

void main() {
  testWidgets('an accepted booking shows the protected start code and calls', (
    tester,
  ) async {
    final secure = _secureCalls();
    final h = await _live(tester, booking());
    expect(find.text('Rahim Uddin accepted your booking'), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    expect(find.text('House 12, Road 5'), findsOneWidget);
    expect(secure, ['true']);
    expect(h.services.prefs.string('pao.startCode.b1'), '4821');
    await tester.tap(find.byIcon(Icons.call_outlined));
    expect(h.launched.single.toString(), 'tel:01711111111');
    h.http.onGet(
      bookingPath,
      (s) => s.reply(200, booking(status: 'on_the_way')),
    );
    await tester.pump(const Duration(seconds: 5));
    await h.settle(tester);
    expect(find.text('Rahim Uddin is on the way'), findsOneWidget);
    await tester.tap(find.text('Cancel booking'));
    await h.settle(tester);
    expect(find.byType(CancelPage), findsOneWidget);
    await h.go(tester, Routes.home);
    expect(secure, ['true', 'false']);
  });

  testWidgets('arrived and in progress; the code is forgotten after start', (
    tester,
  ) async {
    final h = await _live(
      tester,
      booking(status: 'arrived', scheduledAt: '2026-10-09T05:00:00Z'),
    );
    expect(find.text('Rahim Uddin has arrived'), findsOneWidget);
    expect(find.text('Scheduled for 9 Oct 2026, 11:00 AM'), findsOneWidget);
    h.http.onGet(
      bookingPath,
      (s) => s.reply(200, booking(status: 'in_progress')),
    );
    await tester.pump(const Duration(seconds: 5));
    await h.settle(tester);
    expect(find.text('Job in progress'), findsOneWidget);
    expect(find.text('4821'), findsNothing);
    expect(h.services.prefs.string('pao.startCode.b1'), '');
    await tester.tap(find.text('Report a problem'));
    await h.settle(tester);
    expect(find.text('C20'), findsOneWidget);
  });

  testWidgets('new extras open the approval screen', (tester) async {
    final h = await _live(
      tester,
      booking(status: 'in_progress', pendingExtras: proposal()),
    );
    expect(find.byType(ExtrasPage), findsOneWidget);
    expect(find.text('Item x3 × 1'), findsOneWidget);
    expect(find.text('৳1,800'), findsOneWidget);
    h.http.onPost(
      '$bookingPath/extras/decision',
      (s) => s.reply(409, apiError('EXTRAS_PENDING')),
    );
    await tester.tap(find.text('Approve'));
    await h.settle(tester);
    expect(find.byType(ExtrasPage), findsOneWidget);
    h.http
      ..onPost(
        '$bookingPath/extras/decision',
        (s) => s.reply(200, booking(status: 'in_progress')),
      )
      ..onGet(
        bookingPath,
        (s) => s.reply(
          200,
          booking(
            status: 'in_progress',
            pendingExtras: proposal(status: 'approved'),
          ),
        ),
      );
    await tester.tap(find.text('Decline'));
    await h.settle(tester);
    expect(h.bodyOf('$bookingPath/extras/decision'), {
      'proposalId': 'p1',
      'approve': false,
    });
    expect(find.byType(LivePage), findsOneWidget);
    expect(find.text('Extra items to approve'), findsNothing);
  });

  testWidgets('the extras card reopens approval', (tester) async {
    final h = await _live(
      tester,
      booking(status: 'in_progress', pendingExtras: proposal()),
    );
    await tester.tap(find.byTooltip('Back'));
    await h.settle(tester);
    expect(find.text('Extra items to approve'), findsOneWidget);
    expect(find.text('Your provider added ৳500 of items.'), findsOneWidget);
    await tester.tap(find.text('Review'));
    await h.settle(tester);
    expect(find.byType(ExtrasPage), findsOneWidget);
  });

  testWidgets('approval with nothing pending goes back to the booking', (
    tester,
  ) async {
    final h = await openBooking(
      tester,
      booking(status: 'in_progress'),
      'extras',
    );
    expect(find.text('No extra items are waiting for you.'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await h.settle(tester);
    expect(find.byType(LivePage), findsOneWidget);
  });

  testWidgets('a completed job shows the bill and leads to rating', (
    tester,
  ) async {
    final h = await _live(tester, booking(status: 'completed'), code: false);
    expect(find.byType(CompletedPage), findsOneWidget);
    expect(find.text('Pay ৳1,300 in cash'), findsOneWidget);
    expect(find.text('Hand the cash to Rahim Uddin.'), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
    await tester.tap(find.text('View receipt'));
    await h.settle(tester);
    expect(find.text('C64'), findsOneWidget);
    await h.go(tester, Routes.booking('b1', 'completed'));
    await tester.tap(find.text('Rate Rahim Uddin'));
    await h.settle(tester);
    expect(find.byType(RatingPage), findsOneWidget);
  });

  testWidgets('a paid and rated job only offers the receipt and home', (
    tester,
  ) async {
    final h = await _live(
      tester,
      booking(status: 'completed', cashReceived: true, reviewedByMe: true),
    );
    expect(find.text('৳1,300 paid in cash'), findsOneWidget);
    expect(find.textContaining('Rate'), findsNothing);
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
  });

  testWidgets('offline, the saved start code is still shown', (tester) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    await h.services.prefs.setString('pao.startCode.b1', '4821');
    h.http
      ..onGet(bookingPath, (s) => s.reply(503, apiError('INTERNAL')))
      ..onGet(_code, (s) => s.reply(503, apiError('INTERNAL')));
    await h.pumpApp(tester, Routes.booking('b1', 'live'));
    expect(find.textContaining('start code is saved'), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    h.http.onGet(bookingPath, (s) => s.reply(200, booking()));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Rahim Uddin accepted your booking'), findsOneWidget);
    h.http.onGet(bookingPath, (s) => s.reply(503, apiError('INTERNAL')));
    await tester.pump(const Duration(seconds: 5));
    await h.settle(tester);
    expect(find.byType(StaleNotice), findsOneWidget);
  });

  testWidgets('a code that cannot be loaded can be retried', (tester) async {
    final h = await _live(
      tester,
      booking(provider: party(phone: null)),
      code: false,
    );
    expect(find.byIcon(Icons.call_outlined), findsNothing);
    expect(
      find.text('This was already changed. Refresh and try again.'),
      findsOneWidget,
    );
    h.http.onGet(_code, (s) => s.reply(200, {'code': '1234'}));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('1234'), findsOneWidget);
  });

  testWidgets('a cancelled booking says so', (tester) async {
    await _live(tester, booking(status: 'cancelled'));
    expect(find.text('Booking cancelled'), findsOneWidget);
  });

  testWidgets('an unanswered booking goes back to waiting', (tester) async {
    await _live(tester, booking(status: 'requested'));
    expect(find.byType(WaitingPage), findsOneWidget);
  });

  testWidgets('a failed load without a saved code can be retried', (
    tester,
  ) async {
    final h = await _live(tester, booking(), code: false);
    h.http.onGet(bookingPath, (s) => s.reply(404, apiError('NOT_FOUND')));
    await tester.tap(find.text('Cancel booking'));
    await h.settle(tester);
    await tester.tap(find.byTooltip('Back'));
    await h.settle(tester);
    expect(find.byType(LivePage), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await h.settle(tester);
    expect(find.byType(StaleNotice), findsOneWidget);
  });

  testWidgets('the live booking reads in Bangla', (tester) async {
    final h = await _live(tester, booking(status: 'on_the_way'));
    h.services.locale.select(const Locale('bn'));
    await h.settle(tester);
    expect(find.text('Rahim Uddin পথে আছেন'), findsOneWidget);
    expect(find.text('৳১,৩০০'), findsOneWidget);
  });
}
