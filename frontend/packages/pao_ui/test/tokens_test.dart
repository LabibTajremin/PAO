import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

void main() {
  test('every accent drives the scheme and the extension', () {
    for (final accent in AccentPreset.values) {
      final theme = PaoTheme.light(accent: accent);
      expect(theme.colorScheme.primary, accent.primary);
      expect(theme.extension<PaoColors>()!.accent, accent);
    }
    expect(AccentPreset.values, hasLength(10));
    expect(PaoTheme.light().colorScheme.primary, const Color(0xFF1F3A6E));
  });

  test('colour extension copies and lerps', () {
    const a = PaoColors(AccentPreset.midnight);
    const b = PaoColors(AccentPreset.plum);
    expect(a.copyWith().accent, AccentPreset.midnight);
    expect(a.copyWith(accent: AccentPreset.onyx).accent, AccentPreset.onyx);
    expect(a.lerp(b, 0.2).accent, AccentPreset.midnight);
    expect(a.lerp(b, 0.8).accent, AccentPreset.plum);
    expect(a.lerp(null, 0.8).accent, AccentPreset.midnight);
  });

  testWidgets('context.pao falls back to Midnight without the extension', (
    tester,
  ) async {
    late PaoColors got;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          got = context.pao;
          return const SizedBox();
        },
      ),
    );
    expect(got.accent, AccentPreset.midnight);
    await pumpPao(
      tester,
      Builder(
        builder: (context) {
          got = context.pao;
          return const SizedBox();
        },
      ),
      accent: AccentPreset.petrol,
    );
    expect(got.accent, AccentPreset.petrol);
  });

  test('type scale uses the bundled fonts', () {
    final text = paoTextTheme();
    expect(text.bodyLarge!.fontFamily, PaoFonts.latin);
    expect(text.bodyLarge!.fontFamilyFallback, [PaoFonts.bangla]);
    expect(PaoSpace.lg, 16);
    expect(PaoRadius.pill, greaterThan(PaoRadius.xl));
  });
}
