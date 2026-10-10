import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/rating/domain/rating_repository.dart';
import 'package:pao_customer/features/rating/presentation/rating_cubit.dart';

import '../../support/harness.dart';
import '../booking/booking_fixtures.dart';

const _review = '$bookingPath/review';

Map<String, Object?> _completed() => booking(status: 'completed');

class _Repo implements RatingRepository {
  Map<String, Object?> json = _completed();
  AppFailure? fail;
  final sent = <ProviderReview>[];

  @override
  Future<Booking> booking(String id) async {
    if (fail != null) throw fail!;
    return Booking.fromJson(json);
  }

  @override
  Future<void> review(String id, ProviderReview review) async {
    sent.add(review);
    if (fail != null) throw fail!;
  }
}

void main() {
  test('rating cubit limits tags and treats a repeat as rated', () async {
    final repo = _Repo();
    final cubit = RatingCubit(repo, 'b1');
    await cubit.load();
    await cubit.submit('x');
    expect(repo.sent, isEmpty);
    RatingCubit.tags.forEach(cubit.toggle);
    expect(cubit.state.tags, hasLength(RatingCubit.maxTags));
    cubit
      ..toggle(ReviewTag.onTime)
      ..rate(4);
    expect(cubit.state.tags, isNot(contains(ReviewTag.onTime)));
    repo.fail = const NetworkFailure();
    await cubit.submit(' Great ');
    expect([cubit.state.failure!.code, cubit.state.done], ['NETWORK', false]);
    expect(repo.sent.single.comment, 'Great');
    repo.fail = const ApiFailure('REVIEW_ALREADY_SUBMITTED', status: 409);
    await cubit.submit('');
    expect([cubit.state.failure, cubit.state.done], [null, true]);
    repo
      ..fail = null
      ..json = booking(status: 'completed', reviewedByMe: true);
    await cubit.load();
    expect(cubit.state.done, isTrue);
    repo.fail = const NetworkFailure();
    await cubit.load();
    expect(cubit.state.view, isA<ViewFailure<Booking>>());
  });

  testWidgets('stars, tags and a comment are sent, then thanks', (
    tester,
  ) async {
    final h = await openBooking(tester, _completed(), 'rate');
    expect(find.text('How was Rahim Uddin?'), findsOneWidget);
    await tester.tap(find.byTooltip('4'));
    await tester.tap(find.text('On time'));
    await tester.tap(find.text('Late'));
    await tester.tap(find.text('Messy'));
    for (final tag in ['Professional', 'Quality work', 'Clean', 'Friendly']) {
      await tester.tap(find.text(tag));
    }
    await tester.tap(find.text('Fair price'));
    await tester.tap(find.text('Rude'));
    await tester.tap(find.text('Poor quality'));
    await tester.enterText(find.byType(TextField), 'Quick fix');
    h.http.onPost(_review, (s) => s.reply(422, apiError('REVIEW_NOT_ALLOWED')));
    await tester.tap(find.text('Submit rating'));
    await h.settle(tester);
    expect(find.byType(TextField), findsOneWidget);
    h.http.onPost(
      _review,
      (s) => s.reply(201, {
        'id': 'r1',
        'bookingId': 'b1',
        'stars': 4,
        'tags': ['on_time'],
        'authorName': 'Nusrat',
        'createdAt': '2026-10-09T05:00:00Z',
      }),
    );
    await tester.tap(find.text('Submit rating'));
    await h.settle(tester);
    final body = h.bodyOf(_review)! as Map<String, Object?>;
    expect(
      [body['stars'], body['comment'], (body['tags']! as List).length],
      [4, 'Quick fix', 6],
    );
    expect(find.text('Thanks for your rating!'), findsOneWidget);
    await tester.tap(find.text('My bookings'));
    await h.settle(tester);
    expect(find.text('C18'), findsOneWidget);
  });

  testWidgets('a rated booking thanks at once; skipping goes home', (
    tester,
  ) async {
    final h = await openBooking(
      tester,
      booking(status: 'completed', reviewedByMe: true),
      'rate',
    );
    await tester.tap(find.text('Back to home'));
    await h.settle(tester);
    expect(find.text('C07'), findsOneWidget);
    await h.go(tester, '/bookings/b2/rate');
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('skip leaves without rating, in Bangla too', (tester) async {
    final h = await openBooking(tester, _completed(), 'rate');
    h.services.locale.select(const Locale('bn'));
    await h.settle(tester);
    expect(find.text('Rahim Uddin-এর কাজ কেমন ছিল?'), findsOneWidget);
    await tester.tap(find.text('এখন নয়'));
    await h.settle(tester);
    expect(find.byType(TextField), findsNothing);
  });
}
