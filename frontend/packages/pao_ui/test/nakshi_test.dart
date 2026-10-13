import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// Text on a translucent fill is read against the fill blended over the card.
Color _over(Color fill, Color base) => Color.alphaBlend(fill, base);

void _expectAA(Color fg, Color bg, String what) => expect(
  _contrast(fg, bg),
  greaterThanOrEqualTo(4.5),
  reason: '$what: ${_contrast(fg, bg).toStringAsFixed(2)}',
);

void main() {
  test('text colours meet WCAG AA on paper, card and well in both modes', () {
    for (final dark in [false, true]) {
      final c = PaoColors(AccentPreset.midnight, dark: dark);
      for (final bg in [c.paper, c.card, c.well]) {
        for (final fg in [c.ink, c.inkMuted, c.inkFaint, c.dangerInk]) {
          _expectAA(fg, bg, 'dark=$dark $fg on $bg');
        }
      }
      for (final tone in [c.successInk, c.warningInk, c.dangerInk]) {
        _expectAA(tone, _over(tone.withValues(alpha: 0.12), c.card), 'badge');
      }
    }
  });

  test('every accent meets WCAG AA for actions in both modes', () {
    for (final accent in AccentPreset.values) {
      for (final dark in [false, true]) {
        final c = PaoColors(accent, dark: dark);
        final name = '${accent.name} dark=$dark';
        _expectAA(c.onAction, c.action, '$name label on action');
        _expectAA(c.action, c.paper, '$name accent text on paper');
        _expectAA(c.selectedInk, c.selectedFill, '$name selected');
        _expectAA(c.action, c.tintFill, '$name icon on tint');
      }
    }
  });

  test('dark theme uses the ink palette and keeps the accent', () {
    final theme = PaoTheme.dark(accent: AccentPreset.petrol);
    final c = theme.extension<PaoColors>()!;
    expect(c.dark, isTrue);
    expect(c.accent, AccentPreset.petrol);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, c.paper);
    expect(theme.colorScheme.primary, AccentPreset.petrol.soft);
    expect(theme.textTheme.bodyMedium!.color, c.ink);
    expect(c.copyWith(dark: false).dark, isFalse);
    expect(c.copyWith().dark, isTrue);
    expect(PaoTheme.light().scaffoldBackgroundColor, PaoColors.canvas);
  });

  test('headings use Fraunces with Bangla fallback; body stays sans', () {
    final text = paoTextTheme();
    for (final s in [text.displaySmall!, text.titleLarge!]) {
      expect(s.fontFamily, PaoFonts.display);
      expect(s.fontFamilyFallback, [PaoFonts.bangla]);
    }
    expect(text.bodyMedium!.fontFamily, PaoFonts.latin);
    expect(PaoShape.leaf.bottomRight.x, PaoShape.tip);
    expect(PaoShape.leaf.topLeft.x, PaoShape.round);
    expect(PaoMotion.fast, lessThan(PaoMotion.base));
  });

  test('stitch painter repaints only when its look changes', () {
    const a = PaoStitchPainter(color: Colors.red);
    expect(a.shouldRepaint(const PaoStitchPainter(color: Colors.red)), isFalse);
    expect(a.shouldRepaint(const PaoStitchPainter(color: Colors.blue)), isTrue);
    expect(
      a.shouldRepaint(
        const PaoStitchPainter(color: Colors.red, frame: PaoShape.leaf),
      ),
      isTrue,
    );
  });

  testWidgets('stitches draw lines, dividers and frames', (tester) async {
    await pumpPao(
      tester,
      const Column(
        children: [
          PaoStitchDivider(),
          SizedBox(height: 40, child: PaoStitch(axis: Axis.vertical)),
          PaoStitch(length: 30, color: Colors.teal),
          PaoStitchFrame(frame: PaoShape.leaf, child: Text('framed')),
        ],
      ),
    );
    expect(find.text('framed'), findsOneWidget);
    expect(tester.getSize(find.byType(PaoStitch).at(2)).width, 30);
    expect(tester.getSize(find.byType(PaoStitch).at(1)).height, 40);
  });

  testWidgets('gallery switches to dark mode and money is tabular', (
    tester,
  ) async {
    tallScreen(tester);
    await pumpPao(tester, const PaoGalleryPage());
    await tester.tap(find.text('dark'));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(PaoStepper)));
    expect(theme.brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
    final money = tester.widget<Text>(
      find.descendant(
        of: find.byType(PaoMoneyText),
        matching: find.byType(Text),
      ),
    );
    expect(money.style!.fontFeatures, [const FontFeature.tabularFigures()]);
    await tester.tap(find.text('dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(PaoStepper))).brightness,
      Brightness.light,
    );
  });
}
