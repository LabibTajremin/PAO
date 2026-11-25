import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

Widget _app(Future<void>? ready, {bool reduced = false}) => MaterialApp(
  theme: PaoTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: PaoOpening(ready: ready, child: child!),
  ),
  home: const Scaffold(body: Text('home')),
);

/// Steps frames through [time], as a device would.
Future<void> _run(WidgetTester tester, Duration time) async {
  for (var t = Duration.zero; t < time; t += PaoMotion.itemStagger) {
    await tester.pump(PaoMotion.itemStagger);
  }
}

Finder get _splash => find.byWidgetPredicate(
  (w) =>
      w is ColoredBox &&
      (w.color == PaoSplash.light || w.color == PaoSplash.dark),
);

void main() {
  testWidgets('the opening layers load before the first frame', (tester) async {
    await tester.runAsync(precacheOpening);
    expect(svg.cache.count, greaterThanOrEqualTo(8));
  });

  testWidgets('without a load the app shows at once', (tester) async {
    await tester.pumpWidget(_app(null));
    expect(find.text('home'), findsOneWidget);
    expect(_splash, findsNothing);
  });

  testWidgets('a quick load settles the letters then opens in time', (
    tester,
  ) async {
    await tester.pumpWidget(_app(Future.value()));
    expect(_splash, findsOneWidget);
    expect(find.byType(OpeningLogo), findsOneWidget);
    // The first frame is the splash: letters at full size.
    final scales = tester.widgetList<ScaleTransition>(
      find.descendant(
        of: find.byType(OpeningLogo),
        matching: find.byType(ScaleTransition),
      ),
    );
    expect(scales.map((s) => s.scale.value), everyElement(1));
    await _run(tester, openingSettle + PaoMotion.base * 2);
    expect(_splash, findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a slow load waits on the settled logo with a progress line', (
    tester,
  ) async {
    final load = Completer<void>();
    await tester.pumpWidget(_app(load.future));
    await _run(tester, openingSettle * 2);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('home'), findsNothing);
    load.completeError(StateError('offline'));
    await _run(tester, PaoMotion.base * 2);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('reduced motion skips the settle; dark mode uses the dark tile', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final load = Completer<void>();
    await tester.pumpWidget(_app(load.future, reduced: true));
    await tester.pump();
    expect(tester.widget<ColoredBox>(_splash).color, PaoSplash.dark);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    load.complete();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('leaving before the load finishes is harmless', (tester) async {
    final load = Completer<void>();
    await tester.pumpWidget(_app(load.future));
    await tester.pumpWidget(const SizedBox());
    load.complete();
    await tester.pump();
    expect(find.text('home'), findsNothing);
  });
}
