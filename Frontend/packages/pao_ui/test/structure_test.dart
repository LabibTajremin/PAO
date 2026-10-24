import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets('bottom sheet opens with its title', (tester) async {
    await pumpPao(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showPaoSheet<void>(
            context,
            title: 'Log out?',
            child: const Text('Body'),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('empty and error states', (tester) async {
    tallScreen(tester);
    var retried = false;
    await pumpPao(
      tester,
      Column(
        children: [
          Expanded(
            child: PaoEmptyState(
              title: 'No bookings',
              message: 'Book a service',
              action: PaoButton(label: 'Book', onPressed: () {}),
            ),
          ),
          Expanded(
            child: PaoErrorState(
              title: 'Oops',
              message: 'No connection',
              onRetry: () => retried = true,
            ),
          ),
          const Expanded(
            child: PaoErrorState(title: 'Bare', message: 'm'),
          ),
          const Expanded(child: PaoEmptyState(title: 'Only title')),
        ],
      ),
    );
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
    expect(find.byIcon(Icons.inbox_outlined), findsNWidgets(2));
  });

  testWidgets('bottom nav and app bar', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: PaoTheme.light(),
        home: Scaffold(
          appBar: const PaoAppBar(title: 'Bookings'),
          bottomNavigationBar: PaoBottomNav(
            index: 0,
            onSelected: (i) => tapped = i,
            items: const [
              PaoNavItem(icon: Icons.home, label: 'Home'),
              PaoNavItem(
                icon: Icons.notifications,
                label: 'Alerts',
                badge: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Alerts'));
    expect(tapped, 1);
    expect(find.text('Bookings'), findsOneWidget);
    expect(PaoAppBar(title: ['x'].first).preferredSize.height, kToolbarHeight);
    expect(PaoNavItem(icon: Icons.home, label: ['y'].first).badge, isFalse);
  });

  testWidgets('placeholder page shows its title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PlaceholderPage(title: ['PAO'].first)),
    );
    expect(find.text('PAO'), findsOneWidget);
  });
}
