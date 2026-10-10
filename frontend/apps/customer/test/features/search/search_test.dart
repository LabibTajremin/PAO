import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/home/presentation/services_page.dart';
import 'package:pao_customer/features/search/domain/search_repository.dart';
import 'package:pao_customer/features/search/presentation/search_cubit.dart';
import 'package:pao_customer/features/service/presentation/service_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';
import '../service/fixtures.dart';

class _Repo implements SearchRepository {
  final asked = <String>[];
  final pending = <String, Completer<CatalogSearchResults>>{};
  bool fail = false;

  @override
  Future<CatalogSearchResults> search(String query) {
    asked.add(query);
    if (fail) return Future.error(const NetworkFailure());
    return (pending[query] = Completer()).future;
  }
}

final _found = CatalogSearchResults.fromJson({
  'services': [service()],
  'subServices': <Object?>[],
});

const _search = '/v1/customer/catalog/search';

void main() {
  test('search waits for a pause and ignores stale answers', () async {
    final repo = _Repo();
    final cubit = SearchCubit(repo, delay: const Duration(milliseconds: 5))
      ..query('fa')
      ..query(' fan ');
    expect(cubit.state.loading, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repo.asked, ['fan']);
    cubit.query('fan repair');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    repo.pending['fan']!.complete(_found);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.results, isNull);
    repo.pending['fan repair']!.complete(
      CatalogSearchResults(services: const [], subServices: const []),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.nothingFound, isTrue);
    repo.fail = true;
    await cubit.retry();
    expect(cubit.state.failure!.code, 'NETWORK');
    cubit.query('switch');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    cubit.query('other');
    expect(cubit.state.failure, isNull);
    cubit.query(' ');
    expect(cubit.state.query, isEmpty);
    await cubit.close();
  });

  testWidgets('results, no results and failures', (tester) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    h.http.onGet(
      _search,
      (s) => s.reply(200, {
        'services': [service()],
        'subServices': [sub(fanId, 'Fan repair')],
      }),
    );
    await h.pumpApp(tester, Routes.search);
    expect(find.text('What do you need help with?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'fan');
    await tester.pump();
    expect(find.byType(PaoSkeletonList), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await h.settle(tester);
    expect(h.sent.last.queryParameters, {'q': 'fan'});
    expect(find.text('৳500 per unit'), findsOneWidget);
    await tester.tap(find.text('Fan repair'));
    await h.settle(tester);
    expect(
      tester.widget<ServicePage>(find.byType(ServicePage)).preselect,
      fanId,
    );
    await tester.pageBack();
    await h.settle(tester);
    await tester.tap(find.text('Electrician'));
    await h.settle(tester);
    expect(find.byType(ServicePage), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);
    h.http.onGet(_search, (s) => s.reply(500, apiError('INTERNAL')));
    await _type(tester, h, 'zzz');
    expect(find.text('Try again'), findsOneWidget);
    h.http.onGet(
      _search,
      (s) =>
          s.reply(200, {'services': <Object?>[], 'subServices': <Object?>[]}),
    );
    await tester.tap(find.text('Try again'));
    await h.settle(tester);
    expect(find.text('No results for "zzz"'), findsOneWidget);
    await tester.tap(find.text('All services'));
    await h.settle(tester);
    expect(find.byType(ServicesPage), findsOneWidget);
  });
}

Future<void> _type(WidgetTester tester, Harness h, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await h.settle(tester);
}
