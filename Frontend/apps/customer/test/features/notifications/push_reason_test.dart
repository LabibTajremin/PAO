import 'package:flutter_test/flutter_test.dart';

import '../../support/harness.dart';

void main() {
  testWidgets('signing in with an unanswered permission explains first', (
    tester,
  ) async {
    final h = await Harness.create();
    h.push.undecided = true;
    await h.signIn(tester);
    await h.pumpApp(tester);
    expect(find.text('Turn on notifications'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await h.settle(tester);
    expect(find.text('Turn on notifications'), findsNothing);
  });
}
