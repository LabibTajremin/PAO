import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

void main() {
  test('light theme uses the Midnight accent as primary', () {
    expect(PaoTheme.light().colorScheme.primary, PaoTheme.midnight);
  });

  testWidgets('placeholder page shows its title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaceholderPage(title: 'PAO')),
    );
    expect(find.text('PAO'), findsOneWidget);
  });
}
