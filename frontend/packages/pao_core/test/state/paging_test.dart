import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Serves pages of ints; `fail` makes the next fetch throw.
class _Source {
  bool fail = false;
  final cursors = <String?>[];

  Future<Paged<int>> fetch(String? cursor) async {
    cursors.add(cursor);
    if (fail) throw const NetworkFailure();
    return cursor == null ? const Paged([1, 2], 'c2') : const Paged([3]);
  }
}

Future<void> _pump(WidgetTester tester, PagedCubit<int> cubit) =>
    tester.pumpWidget(
      MaterialApp(
        theme: PaoTheme.light(),
        locale: const Locale('en'),
        supportedLocales: PaoLocales.all,
        localizationsDelegates: const [
          PaoL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: PagedView<int>(
              header: const [Text('header')],
              empty: const Text('nothing'),
              itemBuilder: (_, i) => Text('row $i'),
            ),
          ),
        ),
      ),
    );

void main() {
  test('pages append until the last, failures keep the rows', () async {
    final src = _Source();
    final cubit = PagedCubit<int>(src.fetch);
    expect(cubit.state.loading, isTrue);
    await cubit.load();
    expect(
      [cubit.state.items, cubit.state.next],
      [
        [1, 2],
        'c2',
      ],
    );
    src.fail = true;
    await cubit.more();
    expect(
      [cubit.state.items.length, cubit.state.failure!.code],
      [2, 'NETWORK'],
    );
    src.fail = false;
    await cubit.more();
    expect(
      [cubit.state.items, cubit.state.next],
      [
        [1, 2, 3],
        null,
      ],
    );
    await cubit.more();
    expect(src.cursors, [null, 'c2', 'c2']);
    await cubit.close();
  });

  test('a page landing after close is dropped', () async {
    for (final fail in [false, true]) {
      final gate = Completer<void>();
      final cubit = PagedCubit<int>((_) async {
        await gate.future;
        if (fail) throw const NetworkFailure();
        return const Paged([1]);
      });
      final pending = cubit.load();
      await cubit.close();
      gate.complete();
      await pending;
      expect(cubit.state.items, isEmpty);
    }
  });

  test('a page built at runtime keeps its rows', () {
    final rows = [1];
    expect(Paged(rows).next, isNull);
  });

  test('loading() starts a LoadCubit', () async {
    final view = LoadCubit<int>(() async => 1).loading();
    await Future<void>.delayed(Duration.zero);
    expect(view.state, isA<ViewData<int>>());
  });

  testWidgets('view: loading, error, empty, rows and load more', (
    tester,
  ) async {
    final src = _Source()..fail = true;
    final cubit = PagedCubit<int>(src.fetch);
    await _pump(tester, cubit);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await cubit.load();
    await tester.pump();
    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );
    src.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.text('row 2'), findsOneWidget);
    src.fail = true;
    await tester.tap(find.text('Load more'));
    await tester.pump();
    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );
    src.fail = false;
    await tester.tap(find.text('Load more'));
    await tester.pump();
    expect(find.text('row 3'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
    final empty = PagedCubit<int>((_) async => const Paged([]));
    await _pump(tester, empty.loading());
    await tester.pump();
    expect(find.text('nothing'), findsOneWidget);
  });

  testWidgets('a page in flight shows a spinner under the rows', (
    tester,
  ) async {
    final cubit = PagedCubit<int>((c) async => const Paged([1], 'n'));
    await _pump(tester, cubit);
    await cubit.load();
    cubit.emit(const PagedState(items: [1], next: 'n', loading: true));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
