import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/harness.dart';

void main() {
  testWidgets('session expired offers sign-in in both languages', (
    tester,
  ) async {
    var opened = false;
    await pumpPao(tester, PaoSessionExpiredView(onSignIn: () => opened = true));
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(opened, isTrue);
    await pumpPao(
      tester,
      PaoSessionExpiredView(onSignIn: () {}),
      locale: const Locale('bn'),
    );
    expect(find.text('আবার স্বাগতম'), findsOneWidget);
  });

  testWidgets('access denied', (tester) async {
    await pumpPao(tester, PaoAccessDeniedView(key: UniqueKey()));
    expect(find.text('You do not have access to this screen.'), findsOneWidget);
  });
}
