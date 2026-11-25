import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

Widget _light(Widget child) => PaoMotionScope(lowEnd: true, child: child);

class _Route extends StatelessWidget {
  const _Route({required this.next, required this.child});

  final Widget next;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => Scaffold(body: next))),
    child: child,
  );
}

Future<void> _fly(WidgetTester tester, Widget from, Widget to) async {
  await pumpPao(tester, _Route(next: to, child: from));
  await tester.tap(find.byType(_Route));
  await tester.pump();
  await tester.pump(PaoMotion.fast);
  await tester.pumpAndSettle();
  Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
  await tester.pump();
  await tester.pump(PaoMotion.fast);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('money counts up on dashboards, at once in the light set', (
    tester,
  ) async {
    await pumpPao(tester, const PaoMoneyText(150000, countUp: true));
    await tester.pump(PaoMotion.fast);
    expect(find.text('৳1,500'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('৳1,500'), findsOneWidget);
    await pumpPao(tester, _light(const PaoMoneyText(2500, countUp: true)));
    expect(find.text('৳25'), findsOneWidget);
  });

  testWidgets('the first six items rise in once; later ones just appear', (
    tester,
  ) async {
    Widget list(int count) => PaoEntranceGroup(
      child: ListView(
        children: [
          for (var i = 0; i < count; i++)
            PaoEntrance(index: i, child: Text('item $i')),
        ],
      ),
    );
    await pumpPao(tester, list(8));
    await tester.pump(PaoMotion.itemStagger);
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pumpAndSettle();
    await pumpPao(tester, list(9));
    await tester.pumpAndSettle();
    expect(find.text('item 8'), findsOneWidget);
    await pumpPao(tester, const PaoEntrance(index: 0, child: Text('alone')));
    await pumpPao(tester, _light(list(2)));
    expect(find.text('item 1'), findsOneWidget);
  });

  testWidgets('heroes fly, surfaces fly empty and vanishing art fades', (
    tester,
  ) async {
    final art = [PaoHero.signInArt].single;
    await _fly(
      tester,
      const PaoHero(tag: 'a', child: Text('icon')),
      const PaoHero(tag: 'a', child: Text('header')),
    );
    await _fly(
      tester,
      const PaoHero(tag: 'b', surface: true, child: Text('card')),
      const PaoHero(tag: 'b', surface: true, child: Text('detail')),
    );
    await _fly(
      tester,
      const PaoHero(tag: PaoHero.signInArt, child: Text('art')),
      // Built at run time, as the apps do.
      PaoHero.vanish(tag: art, child: const SizedBox(height: 8)),
    );
    expect(PaoHero.service('1'), 'service:1');
    expect(PaoHero.booking('1'), 'booking:1');
    expect(PaoHero.provider('1'), 'provider:1');
  });

  testWidgets('the success mark draws, bursts, and is still when light', (
    tester,
  ) async {
    final size = [72.0].single;
    await pumpPao(tester, PaoSuccessMark(size: size));
    await tester.pump(PaoMotion.fast);
    await tester.pumpAndSettle();
    // A new accent repaints only because the colours changed.
    await pumpPao(
      tester,
      PaoSuccessMark(size: size),
      accent: AccentPreset.values.last,
    );
    expect(find.byType(PaoSuccessMark), findsOneWidget);
    await pumpPao(tester, _light(const PaoSuccessMark(size: 40)));
    await tester.pump();
    expect(find.byType(PaoSuccessMark), findsOneWidget);
  });

  testWidgets('photos decode at the size drawn', (tester) async {
    final image = MemoryImage(Uint8List(0));
    await pumpPao(tester, PaoAvatar(name: 'Rahim', image: image, size: 40));
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isA<ResizeImage>());
    tester.takeException();
  });
}
