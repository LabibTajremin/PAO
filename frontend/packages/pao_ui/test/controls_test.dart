import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets('buttons: every variant, disabled and loading', (tester) async {
    var taps = 0;
    await pumpPao(
      tester,
      Column(
        children: [
          for (final v in PaoButtonVariant.values)
            PaoButton(label: v.name, onPressed: () => taps++, variant: v),
          const PaoButton(label: 'Off', onPressed: null, icon: Icons.add),
          PaoButton(label: 'Busy', onPressed: () => taps++, loading: true),
          PaoButton(label: 'Narrow', onPressed: () {}, expand: false),
        ],
      ),
    );
    await tester.tap(find.text('primary'));
    await tester.tap(find.text('danger'));
    await tester.tap(find.byType(CircularProgressIndicator));
    await tester.tap(find.text('Off'));
    expect(taps, 2);
    expect(find.bySemanticsLabel('Busy'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('text field shows label, prefix and error', (tester) async {
    String? typed;
    await pumpPao(
      tester,
      PaoTextField(
        label: 'Phone',
        prefix: '+880',
        hint: '1XXX',
        error: 'Wrong number',
        onChanged: (v) => typed = v,
      ),
    );
    await tester.enterText(find.byType(TextField), '17');
    expect(typed, '17');
    expect(find.text('Wrong number'), findsOneWidget);
    expect(find.text('+880 '), findsOneWidget);
    await pumpPao(tester, const PaoTextField(label: 'Name'));
    expect(find.text('Name'), findsOneWidget);
  });

  testWidgets('OTP input completes once every digit is in', (tester) async {
    String? code;
    await pumpPao(tester, PaoOtpInput(onCompleted: (c) => code = c));
    await tester.enterText(find.byType(TextField), '12a');
    await tester.pump();
    expect(code, isNull);
    expect(find.text('1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    expect(code, '123456');
    await pumpPao(tester, PaoOtpInput(onCompleted: (_) {}, hasError: true));
    expect(find.bySemanticsLabel('One-time code'), findsOneWidget);
  });

  testWidgets('chips toggle and read as selected', (tester) async {
    var on = false;
    await pumpPao(
      tester,
      Row(
        children: [
          PaoChip(label: 'Rating', selected: true, onTap: () => on = true),
          const PaoChip(label: 'Read only', selected: false, onTap: null),
        ],
      ),
    );
    await tester.tap(find.text('Rating'));
    expect(on, isTrue);
    expect(
      tester.getSemantics(find.text('Rating')),
      matchesSemantics(
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        label: 'Rating',
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('stepper stays within its bounds', (tester) async {
    final values = <int>[];
    Future<void> show(int value) => pumpPao(
      tester,
      PaoStepper(value: value, min: 1, max: 3, onChanged: values.add),
    );
    await show(1);
    await tester.tap(find.byTooltip('Less'));
    await tester.tap(find.byTooltip('More'));
    await show(3);
    await tester.tap(find.byTooltip('More'));
    expect(values, [2]);
    await pumpPao(tester, PaoStepper(value: 0, onChanged: values.add));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('segmented control reports the tapped value', (tester) async {
    String? picked;
    await pumpPao(
      tester,
      PaoSegmented(
        segments: const {'up': 'Upcoming', 'past': 'Past'},
        selected: 'up',
        onChanged: (v) => picked = v,
      ),
    );
    await tester.tap(find.text('Past'));
    expect(picked, 'past');
  });
}
