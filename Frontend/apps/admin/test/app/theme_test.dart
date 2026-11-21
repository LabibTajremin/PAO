import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  testWidgets('the panel opens light; the sidebar switch turns dark on', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester);
    BuildContext ctx() => tester.element(find.text('Dark mode'));
    expect(h.services.themeMode.value, ThemeMode.light);
    expect(Theme.of(ctx()).brightness, Brightness.light);
    await tester.tap(find.text('Dark mode'));
    await h.settle(tester);
    expect(h.services.themeMode.value, ThemeMode.dark);
    expect(Theme.of(ctx()).brightness, Brightness.dark);
    await tester.tap(find.text('Dark mode'));
    await h.settle(tester);
    expect(h.services.themeMode.value, ThemeMode.light);
  });
}
