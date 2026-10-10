import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/booking/presentation/setup_page.dart';

import '../../support/harness.dart';
import '../service/fixtures.dart';
import 'fixtures.dart';

const _profile = '/v1/customer/providers/$rahimId';
const _reviews = '/v1/customer/providers/$rahimId/reviews';

Future<Harness> _start(WidgetTester tester) async {
  tall(tester);
  final h = await Harness.create();
  await h.signIn(tester);
  h.http
    ..onGet(_profile, (s) => s.reply(200, publicProfile()))
    ..onGet(
      _reviews,
      (s) => s.replyCallback(
        200,
        (o) => o.queryParameters['cursor'] == null
            ? {
                'items': [review()],
                'nextCursor': 'c2',
              }
            : {
                'items': [review(author: 'Karim', full: false)],
              },
      ),
    );
  return h;
}

void main() {
  testWidgets('profile, badge explainer, reviews and booking', (tester) async {
    final h = await _start(tester);
    final draft = {'service': electricianId, 'items': '$fanId:2'};
    await h.pumpApp(
      tester,
      Uri(path: Routes.providerOf(rahimId), queryParameters: draft).toString(),
    );
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('Licensed electrician.'), findsOneWidget);
    expect(find.text('210 jobs done · 8 years of experience'), findsOneWidget);
    expect(find.text('On PAO since Mar 2025'), findsOneWidget);
    expect(find.text('132 ratings'), findsOneWidget);
    expect(find.text('Quick and tidy.'), findsOneWidget);
    expect(find.text('On time'), findsOneWidget);
    expect(
      h.sent.lastWhere((o) => o.path == _reviews).queryParameters['limit'],
      3,
    );
    await tester.tap(find.text('What do badges mean?'));
    await tester.pumpAndSettle();
    expect(find.text('About badges'), findsOneWidget);
    expect(find.textContaining('skill test'), findsOneWidget);
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verified'));
    await tester.pumpAndSettle();
    expect(find.text('About badges'), findsOneWidget);
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All reviews'));
    await h.settle(tester);
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Karim · 8 Oct 2026'), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);
    await tester.tap(find.text('Book Rahim Uddin'));
    await h.settle(tester);
    final state = GoRouterState.of(tester.element(find.byType(SetupPage)));
    expect(state.uri.queryParameters, {...draft, 'provider': rahimId});
  });

  testWidgets('a new provider without reviews or a selection', (tester) async {
    final h = await _start(tester);
    h.http
      ..onGet(_profile, (s) => s.reply(500, apiError('INTERNAL')))
      ..onGet(_reviews, (s) => s.reply(200, {'items': <Object?>[]}));
    await h.pumpApp(tester, Routes.providerOf(rahimId));
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(_profile, (s) => s.reply(200, publicProfile(bio: '')));
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('No ratings yet'), findsOneWidget);
    expect(find.text('No reviews yet'), findsOneWidget);
    expect(find.text('About'), findsNothing);
    expect(find.textContaining('Book'), findsNothing);
    await h.go(tester, Routes.providerReviewsOf(rahimId));
    expect(
      find.text('Reviews appear here after completed jobs.'),
      findsOneWidget,
    );
  });
}
