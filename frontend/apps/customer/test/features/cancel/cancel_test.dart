import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/cancel/domain/cancel_repository.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_cubit.dart';
import 'package:pao_customer/features/live/presentation/live_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import '../booking/booking_fixtures.dart';

Map<String, Object?> _accepted() => booking();

class _Repo implements CancelRepository {
  Map<String, Object?> json = _accepted();
  AppFailure? fail;
  final sent = <String>[];

  @override
  Future<Booking> booking(String id) async {
    if (fail != null) throw fail!;
    return Booking.fromJson(json);
  }

  @override
  Future<Booking> cancel(
    String id,
    CustomerCancelInputReasonEnum reason,
    String? note,
  ) async {
    sent.add('${reason.value} $note');
    if (fail != null) throw fail!;
    return Booking.fromJson({...json, 'status': 'cancelled'});
  }
}

void main() {
  test('cancel cubit needs a reason and maps the outcomes', () async {
    final repo = _Repo();
    final cubit = CancelCubit(repo, 'b1');
    await cubit.load();
    expect(cubit.state.outcome, isNull);
    await cubit.submit('x');
    expect(repo.sent, isEmpty);
    cubit.choose(CustomerCancelInputReasonEnum.providerLate);
    repo.fail = const NetworkFailure();
    await cubit.submit('  ');
    expect(cubit.state.failure!.code, 'NETWORK');
    repo.fail = const ApiFailure('CANCELLATION_NOT_ALLOWED', status: 409);
    await cubit.submit('late');
    expect(
      [cubit.state.outcome, cubit.state.failure],
      [CancelOutcome.blocked, null],
    );
    repo.fail = null;
    await cubit.submit('late');
    expect(cubit.state.outcome, CancelOutcome.cancelled);
    expect(repo.sent, [
      'provider_late null',
      'provider_late late',
      'provider_late late',
    ]);
    for (final (status, outcome) in [
      ('cancelled', CancelOutcome.cancelled),
      ('in_progress', CancelOutcome.blocked),
      ('completed', CancelOutcome.blocked),
      ('rejected', CancelOutcome.closed),
      ('timed_out', CancelOutcome.closed),
    ]) {
      repo.json = booking(status: status);
      await cubit.load();
      expect(cubit.state.outcome, outcome, reason: status);
    }
    repo.fail = const NetworkFailure();
    await cubit.load();
    expect(cubit.state.view, isA<ViewFailure<Booking>>());
  });

  testWidgets('cancelling with a reason shows the result', (tester) async {
    final h = await openBooking(tester, booking(), 'cancel');
    expect(
      find.text('Cancelling is free until the job starts.'),
      findsOneWidget,
    );
    await tester.tap(find.text('The provider is late'));
    await tester.enterText(find.byType(TextField), 'Too slow');
    h.http.onPost(
      '$bookingPath/cancel',
      (s) => s.reply(500, apiError('INTERNAL')),
    );
    await tester.tap(find.widgetWithText(PaoButton, 'Cancel booking'));
    await h.settle(tester);
    expect(find.textContaining('service had a problem'), findsOneWidget);
    h.http.onPost(
      '$bookingPath/cancel',
      (s) => s.reply(200, booking(status: 'cancelled')),
    );
    await tester.tap(find.widgetWithText(PaoButton, 'Cancel booking'));
    await h.settle(tester);
    expect(h.bodyOf('$bookingPath/cancel'), {
      'reason': 'provider_late',
      'note': 'Too slow',
    });
    expect(find.text('Booking cancelled'), findsOneWidget);
    await tester.tap(find.text('Book another provider'));
    await h.settle(tester);
    expect(find.text('C10'), findsOneWidget);
  });

  testWidgets('a started job cannot be cancelled', (tester) async {
    final h = await openBooking(tester, booking(), 'cancel');
    await tester.tap(find.text('I changed my mind'));
    await tester.pump();
    h.http.onPost(
      '$bookingPath/cancel',
      (s) => s.reply(409, apiError('CANCELLATION_NOT_ALLOWED')),
    );
    await tester.tap(find.widgetWithText(PaoButton, 'Cancel booking'));
    await h.settle(tester);
    expect(find.text('The job has already started'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await h.settle(tester);
    expect(find.text('C19'), findsOneWidget);
  });

  testWidgets('blocked leads to a report; keep returns to the booking', (
    tester,
  ) async {
    final h = await openBooking(
      tester,
      booking(status: 'in_progress'),
      'cancel',
    );
    await tester.tap(find.text('Report a problem'));
    await h.settle(tester);
    expect(find.text('C20'), findsOneWidget);
    await h.go(tester, Routes.booking('b1', 'live'));
    h.http.onGet(bookingPath, (s) => s.reply(200, booking()));
    await h.go(tester, Routes.booking('b1', 'cancel'));
    await tester.tap(find.text('Keep booking'));
    await h.settle(tester);
    expect(find.text('C19'), findsOneWidget);
  });

  testWidgets('a declined booking has nothing to cancel', (tester) async {
    final h = await openBooking(tester, booking(status: 'rejected'), 'cancel');
    expect(find.text('This booking is no longer active'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
  });

  testWidgets('cancelling from the live booking returns to it', (tester) async {
    final h = await openBooking(tester, booking(), 'live');
    await tester.tap(find.text('Cancel booking'));
    await h.settle(tester);
    await tester.tap(find.text('Keep booking'));
    await h.settle(tester);
    expect(find.byType(LivePage), findsOneWidget);
  });
}
