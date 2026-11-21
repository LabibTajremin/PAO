import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

void main() {
  String assetOf(WidgetTester tester) =>
      (tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader
              as SvgAssetLoader)
          .assetName;

  testWidgets('the ink logo on light, the inverse on dark', (tester) async {
    for (final (theme, file) in [
      (PaoTheme.light(), 'logo-tile-light.svg'),
      (PaoTheme.dark(), 'logo-tile-dark.svg'),
    ]) {
      await tester.pumpWidget(MaterialApp(theme: theme, home: const PaoLogo()));
      await tester.pumpAndSettle();
      expect(assetOf(tester), endsWith(file));
    }
    expect(find.bySemanticsLabel('PAO'), findsOneWidget);
  });

  testWidgets('the wordmark, and an explicit inverse on any theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PaoTheme.light(),
        home: const PaoLogo(variant: PaoLogoVariant.wordmark, inverse: true),
      ),
    );
    expect(assetOf(tester), endsWith('wordmark-ivory.svg'));
    expect(
      PaoLogo.assetFor(PaoLogoVariant.wordmark, inverse: false),
      endsWith('wordmark-ink.svg'),
    );
  });

  testWidgets('the watermark is ink on light and ivory on dark', (
    tester,
  ) async {
    for (final (theme, tinted) in [
      (PaoTheme.light(), false),
      (PaoTheme.dark(), true),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: PaoWatermark(width: 200, key: UniqueKey()),
        ),
      );
      await tester.pumpAndSettle();
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter != null, tinted);
      expect(assetOf(tester), endsWith('watermark.svg'));
    }
  });
}
