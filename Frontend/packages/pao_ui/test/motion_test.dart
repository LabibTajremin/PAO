import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

Widget _app(Widget home, {bool reduced = false, bool lowEnd = false}) =>
    MaterialApp(
      theme: PaoTheme.light(platform: TargetPlatform.android),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: PaoMotionScope(lowEnd: lowEnd, child: child!),
      ),
      home: home,
    );

class _Opener extends StatelessWidget {
  const _Opener();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const Text('second page')),
        ),
        child: const Text('push'),
      ),
      TextButton(
        onPressed: () => showPaoDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('dialog body')),
        ),
        child: const Text('dialog'),
      ),
      TextButton(
        onPressed: () => showPaoSheet<void>(
          context,
          title: 'Sheet',
          child: const Text('in'),
        ),
        child: const Text('sheet'),
      ),
    ],
  );
}

Future<void> _openAll(WidgetTester tester) async {
  for (final (tap, shown) in [
    ('push', 'second page'),
    ('dialog', 'dialog body'),
    ('sheet', 'in'),
  ]) {
    await tester.tap(find.text(tap));
    // A new route is offstage for its first frame.
    await tester.pump();
    await tester.pump(PaoMotion.fast);
    expect(find.text(shown), findsOneWidget);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text(shown))).pop();
    await tester.pumpAndSettle();
  }
}

void main() {
  test('tokens are short and ordered', () {
    expect(PaoMotion.press < PaoMotion.fast, isTrue);
    expect(PaoMotion.pop < PaoMotion.page, isTrue);
    expect(PaoMotion.emphasis.inMilliseconds, 400);
    expect(openingSettle, const Duration(milliseconds: 340));
  });

  test('platforms get the shared axis, Cupertino or the web fade', () {
    final native = paoPageTransitions(web: false).builders;
    expect(native[TargetPlatform.android], isA<PaoPageTransitionsBuilder>());
    expect(native[TargetPlatform.iOS], isA<CupertinoPageTransitionsBuilder>());
    final web = paoPageTransitions(web: true).builders;
    expect(web[TargetPlatform.android], isA<PaoFadePageTransitionsBuilder>());
    const fade = PaoFadePageTransitionsBuilder();
    expect(fade.transitionDuration, fade.reverseTransitionDuration);
  });

  testWidgets('pages, dialogs and sheets animate in both motion sets', (
    tester,
  ) async {
    for (final (reduced, lowEnd) in [
      (false, false),
      (true, false),
      (false, true),
    ]) {
      await tester.pumpWidget(
        _app(
          const Scaffold(body: _Opener()),
          reduced: reduced,
          lowEnd: lowEnd,
        ),
      );
      await _openAll(tester);
    }
  });

  testWidgets('the web fade carries the next page in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PaoTheme.light().copyWith(
          pageTransitionsTheme: paoPageTransitions(web: true),
        ),
        home: const Scaffold(body: _Opener()),
      ),
    );
    await tester.tap(find.text('push'));
    await tester.pump(PaoMotion.press);
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('second page'), findsOneWidget);
  });

  testWidgets('a tab switch fades the stack in again', (tester) async {
    Future<void> show(int index) => pumpPao(
      tester,
      PaoFadeThrough(index: index, child: Text('tab $index')),
    );
    await show(0);
    await show(0);
    await show(1);
    await tester.pump(PaoMotion.fast);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('tab 1'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);
  });
}
