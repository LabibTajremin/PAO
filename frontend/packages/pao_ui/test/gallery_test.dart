import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets('gallery re-themes on accent change', (tester) async {
    tallScreen(tester);
    await pumpPao(tester, PaoGalleryPage(key: UniqueKey()));
    await tester.tap(find.text('plum'));
    await tester.pump();
    final chip = tester.widget<PaoChip>(find.widgetWithText(PaoChip, 'plum'));
    expect(chip.selected, isTrue);
    final theme = Theme.of(tester.element(find.byType(PaoStepper)));
    expect(theme.colorScheme.primary, AccentPreset.plum.primary);
    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('Past'));
    await tester.tap(find.text('Fan installation'));
    for (final v in PaoButtonVariant.values) {
      await tester.tap(find.text(v.name));
    }
  });

  testWidgets('text at 1.3x fits without overflow, targets are 48 dp', (
    tester,
  ) async {
    tallScreen(tester);
    final handle = tester.ensureSemantics();
    await pumpPao(tester, const PaoGalleryPage(), textScale: 1.3);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
