import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_e2e/secrets_file.dart';
import 'package:pao_partner/app/app.dart';

import 'support/enrol_ui.dart';
import 'support/stack_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a provider signs in, enrols, is approved to Level 1 and goes '
      'online', (tester) async {
    final stack = StackClient.fromDefines();
    final phone = uniquePhone('018');
    final services = await stackServices();
    await tester.pumpWidget(PaoApp(services: services));

    await signInWithOtp(tester, stack, phone);
    await openWizard(tester);
    await enrolProfile(tester);
    await enrolDocuments(tester, '1${phone.substring(2)}');
    await enrolContactAndSubmit(tester, stack, '019${phone.substring(3)}');
    await pumpUntil(tester, find.text('Level 0'));

    final provider = await stack.sessionOf(
      services.sessions.session!.accessToken,
    );
    await stackAdmins(stack).approve(provider.id);
    await _pullUntil(tester, find.text('Level 1'));
    expect(find.text('Verified'), findsWidgets);

    await tapText(tester, 'Go to home');
    await tapOn(tester, find.byType(SwitchListTile));
    await pumpUntil(tester, find.text('You are online'));
  });
}

/// Pulls the verification screen down until [finder] shows: approval reaches
/// the provider's status through the worker, a moment after the verifier acts.
Future<void> _pullUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 300),
      1000,
    );
    await idle(tester, const Duration(seconds: 1));
  }
  expect(finder, findsOneWidget);
}
