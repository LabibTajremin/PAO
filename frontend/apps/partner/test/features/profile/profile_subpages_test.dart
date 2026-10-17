import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/verification/presentation/verification_page.dart';

import '../../support/harness.dart';
import '../jobs/fixtures.dart';
import 'fixtures.dart';

void main() {
  Future<Harness> start(WidgetTester tester) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    return h;
  }

  testWidgets('public profile shows what customers see', (tester) async {
    final h = await start(tester);
    h.http
      ..onGet('/v1/provider/profile', (s) => s.reply(200, profile()))
      ..onGet('/v1/provider/rating', (s) => s.reply(200, rating()));
    await h.pumpApp(tester, Routes.profilePage('public'));
    expect(find.text('Licensed electrician.'), findsOneWidget);
    expect(find.text('8 years of experience'), findsOneWidget);
    expect(find.text('Electrician'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('107'), findsOneWidget);
  });

  testWidgets('public profile of a new provider, then a failure', (
    tester,
  ) async {
    final h = await start(tester);
    h.http
      ..onGet(
        '/v1/provider/profile',
        (s) => s.reply(200, {...profile(bio: null), 'experienceYears': 0}),
      )
      ..onGet('/v1/provider/rating', (s) => s.reply(200, rating(count: 0)));
    await h.pumpApp(tester, Routes.profilePage('public'));
    expect(find.text('New to the trade'), findsOneWidget);
    expect(find.text('No ratings yet'), findsOneWidget);
    h.http.onGet(
      '/v1/provider/rating',
      (s) => s.reply(404, apiError('NOT_FOUND')),
    );
    await h.go(tester, Routes.profile);
    await h.go(tester, Routes.profilePage('public'));
    expect(find.text('We could not find that.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('We could not find that.'), findsOneWidget);
  });

  testWidgets('reviews list with tags, paging and an empty state', (
    tester,
  ) async {
    final h = await start(tester);
    h.http.onGet(
      '/v1/provider/reviews',
      (s) => s.replyCallback(
        200,
        (o) => o.queryParameters['cursor'] == null
            ? {
                'items': [review()],
                'nextCursor': 'c2',
              }
            : {
                'items': [
                  review(author: 'Karim', comment: null, service: false),
                ],
              },
      ),
    );
    await h.pumpApp(tester, Routes.profilePage('reviews'));
    expect(find.text('Quick and tidy.'), findsOneWidget);
    expect(find.text('Nusrat · 8 Oct 2026'), findsOneWidget);
    expect(find.text('On time'), findsOneWidget);
    expect(find.text('Clean'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Karim · 8 Oct 2026'), findsOneWidget);
    h.http.onGet(
      '/v1/provider/reviews',
      (s) => s.reply(200, {'items': <Object?>[]}),
    );
    await h.go(tester, Routes.profile);
    await h.go(tester, Routes.profilePage('reviews'));
    expect(find.text('No reviews yet'), findsOneWidget);
  });

  testWidgets('documents show status, expiry and link to re-upload', (
    tester,
  ) async {
    final h = await start(tester);
    h.http.onGet(
      '/v1/provider/verification',
      (s) => s.reply(200, verificationStatus()),
    );
    await h.pumpApp(tester, Routes.profilePage('documents'));
    expect(find.text('National ID'), findsOneWidget);
    expect(
      find.text(
        'Expires on 20 Oct 2026. Renew it soon to keep receiving bookings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Photo is blurred.'), findsOneWidget);
    expect(
      find.text(
        'Expired on 1 Sep 2026. Bookings are paused until you renew it.',
      ),
      findsOneWidget,
    );
    expect(find.text('Valid until 1 Oct 2027'), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
    await tester.tap(find.text('Update documents'));
    await h.settle(tester);
    expect(find.byType(VerificationPage), findsOneWidget);
  });

  testWidgets('documents can be empty', (tester) async {
    final h = await start(tester);
    h.http.onGet(
      '/v1/provider/verification',
      (s) => s.reply(200, verificationStatus(items: [])),
    );
    await h.pumpApp(tester, Routes.profilePage('documents'));
    expect(find.text('No documents yet'), findsOneWidget);
  });
}
