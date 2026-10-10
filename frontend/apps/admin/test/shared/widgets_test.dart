import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/shared/confirm_reason.dart';
import 'package:pao_admin/shared/detail_drawer.dart';
import 'package:pao_admin/shared/filter_bar.dart';
import 'package:pao_admin/shared/paged_table.dart';
import 'package:pao_core/pao_core.dart';

import '../support/harness.dart';

void main() {
  testWidgets('the table shows a header, rows, opens a row and loads more', (
    tester,
  ) async {
    desktop(tester);
    final cubit = PagedCubit<int>(
      (c) async => c == null ? const Paged([1, 2], 'n') : const Paged([3]),
    );
    final opened = <int>[];
    final searched = <String>[];
    await pumpPage(
      tester,
      Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: PagedTable<int>(
            header: [FilterBar(search: searched.add, searchHint: 'Find')],
            columns: [
              AdminColumn('Number', (n) => Text('n$n'), flex: 2),
              AdminColumn('Double', (n) => Text('${n * 2}')),
            ],
            empty: const Text('none'),
            onOpen: opened.add,
          ),
        ),
      ),
    );
    await tester.runAsync(cubit.load);
    await tester.pumpAndSettle();
    expect(find.text('Number'), findsOneWidget);
    await tester.tap(find.text('n2'));
    expect(opened, [2]);
    await tester.tap(find.text('Load more'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('6'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'rahim');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(searched, ['rahim']);
  });

  testWidgets('a table without an opener has plain rows', (tester) async {
    final cubit = PagedCubit<int>((_) async => const Paged([1]));
    await pumpPage(
      tester,
      Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: PagedTable<int>(
            columns: [AdminColumn('Number', (n) => Text('n$n'))],
            empty: const Text('none'),
          ),
        ),
      ),
    );
    await tester.runAsync(cubit.load);
    await tester.pumpAndSettle();
    await tester.tap(find.text('n1'));
    expect(find.byType(FilterBar), findsNothing);
  });

  testWidgets('the detail drawer slides in and closes', (tester) async {
    desktop(tester);
    await pumpPage(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showDetailDrawer<void>(
            context,
            title: 'Rahim',
            child: const Text('details'),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('details'), findsNothing);
  });

  testWidgets('a reason is required, can start from a template', (
    tester,
  ) async {
    final results = <String?>[];
    await pumpPage(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(
            await confirmWithReason(
              context,
              title: 'Suspend provider',
              confirmLabel: 'Suspend',
              templates: ['Repeated no-shows'],
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suspend'));
    await tester.pumpAndSettle();
    expect(find.text('Write at least 5 characters.'), findsOneWidget);
    await tester.tap(find.text('Repeated no-shows'));
    await tester.tap(find.text('Suspend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results, ['Repeated no-shows', null]);
  });
}
