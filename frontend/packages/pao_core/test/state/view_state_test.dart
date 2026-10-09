import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: PaoTheme.light(),
    locale: const Locale('en'),
    supportedLocales: PaoLocales.all,
    localizationsDelegates: const [
      PaoL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  ),
);

void main() {
  test('load cubit goes loading → data, and reports failures', () async {
    var fail = false;
    final cubit = LoadCubit<int>(() async {
      if (fail) {
        throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        );
      }
      return 7;
    });
    expect(cubit.state, isA<ViewLoading<int>>());
    await cubit.load();
    expect((cubit.state as ViewData<int>).data, 7);
    fail = true;
    await cubit.refresh();
    expect((cubit.state as ViewFailure<int>).failure.code, 'NETWORK');
    await cubit.close();
    await cubit.refresh();
    fail = false;
    await cubit.refresh();
  });

  test('attempt returns the failure or null', () async {
    expect(await attempt(() async {}), isNull);
    expect(
      (await attempt(() async => throw const SessionExpiredFailure()))!.code,
      'SESSION_EXPIRED',
    );
  });

  testWidgets('view renders each state', (tester) async {
    var retried = false;
    Widget view(ViewState<List<int>> s, {Widget? empty}) =>
        ViewStateView<List<int>>(
          state: s,
          onRetry: () => retried = true,
          isEmpty: (d) => d.isEmpty,
          empty: empty,
          builder: (_, d) => Text('items ${d.length}'),
        );
    await _pump(tester, view(const ViewLoading()));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await _pump(tester, view(const ViewFailure(NetworkFailure())));
    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
    await _pump(tester, view(const ViewData([])));
    expect(find.text('Nothing here yet'), findsOneWidget);
    await _pump(tester, view(const ViewData([]), empty: const Text('none')));
    expect(find.text('none'), findsOneWidget);
    await _pump(tester, view(const ViewData([1, 2])));
    expect(find.text('items 2'), findsOneWidget);
    await _pump(
      tester,
      ViewStateView<int>(
        state: const ViewData(1),
        builder: (_, d) => Text('$d'),
      ),
    );
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('offline banner follows the network', (tester) async {
    final online = ValueNotifier(true);
    await _pump(
      tester,
      OfflineBanner(watcher: online, child: const Text('app')),
    );
    expect(find.byType(PaoBanner), findsNothing);
    online.value = false;
    await tester.pump();
    expect(find.byType(PaoBanner), findsOneWidget);
  });
}
