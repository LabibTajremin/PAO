import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pao_customer/features/auth/presentation/phone_page.dart';
import 'package:pao_customer/features/onboarding/presentation/onboarding_page.dart';
import 'package:pao_customer/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the real composition root starts and shows the first screen', (
    tester,
  ) async {
    final errors = <Object>[];
    final started = Completer<void>();
    // The Linux runner has no NetworkManager, so connectivity_plus fails
    // outside the app's control; anything else is a real start-up failure.
    unawaited(
      runZonedGuarded(
        () => app.main().then(started.complete),
        (error, stack) =>
            '$stack'.contains('connectivity_plus') ? null : errors.add(error),
      ),
    );
    await started.future;
    final first = find.byWidgetPredicate(
      (w) => w is OnboardingPage || w is PhonePage,
    );
    for (var i = 0; i < 100 && first.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(first, findsOneWidget);
    expect(errors, isEmpty);
  });
}
