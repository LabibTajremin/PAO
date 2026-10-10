import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/providers/presentation/provider_detail_page.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

const _list = '/v1/admin/providers';

Map<String, Object?> _query(Harness h) =>
    h.sent.lastWhere((o) => o.path == _list).queryParameters;

void main() {
  testWidgets('providers page through filters, search and "load more"', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(
      _list,
      (s) => s.replyCallback(
        200,
        (o) => o.queryParameters['cursor'] == null
            ? {
                'items': [providerSummary(flagged: true)],
                'nextCursor': 'c2',
              }
            : {
                'items': [
                  providerSummary(id: 'p2', name: 'Karim Mia', phone: null),
                ],
              },
      ),
    );
    await h.pumpApp(tester, Routes.providers);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('+8801712345678'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('132'), findsOneWidget);
    expect(find.text('5 Jan 2026'), findsOneWidget);
    expect(find.byIcon(Icons.flag), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await h.settle(tester);
    expect(find.text('Karim Mia'), findsOneWidget);

    await choose(tester, h, 'Status: Any', 'Suspended');
    expect(_query(h)['status'], 'suspended');
    expect(find.text('Status: Suspended'), findsOneWidget);

    await choose(tester, h, 'Level: Any', 'PAO Verified Pro');
    expect(_query(h)['level'], 2);

    await tester.tap(find.text('Flagged for review'));
    await h.settle(tester);
    expect(_query(h)['flagged'], true);

    await tester.enterText(find.byType(TextField), ' 01712 ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle(tester);
    expect(_query(h), containsPair('q', '01712'));
    expect(_query(h)['status'], 'suspended');

    await tester.tap(find.text('Rahim Uddin'));
    await h.settle(tester);
    expect(find.byType(ProviderDetailPage), findsOneWidget);
  });

  testWidgets('narrow screens drop columns; an empty list says so', (
    tester,
  ) async {
    narrow(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(
      _list,
      (s) => s.reply(200, {
        'items': [providerSummary()],
      }),
    );
    await h.pumpApp(tester, Routes.providers);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('Jobs done'), findsNothing);
    h.http.onGet(_list, (s) => s.reply(200, {'items': <Object?>[]}));
    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await h.settle(tester);
    expect(_query(h).containsKey('q'), isFalse);
    expect(find.text('No providers match these filters.'), findsOneWidget);
  });

  testWidgets('a failed list can be retried', (tester) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    h.http.onGet(_list, (s) => s.reply(500, apiError('INTERNAL')));
    await h.pumpApp(tester, Routes.providers);
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(
      _list,
      (s) => s.reply(200, {
        'items': [providerSummary()],
      }),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('Rahim Uddin'), findsOneWidget);
  });
}
