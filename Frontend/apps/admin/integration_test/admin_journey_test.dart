import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pao_admin/app/app.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_ui/pao_ui.dart';

import 'support/web_app.dart';

/// A provider enrolled and submitted over HTTP by run.sh
/// (`dart run pao_e2e:submitted_provider`): the browser cannot read the
/// stack's SMS capture, which enrolment needs.
const _providerId = String.fromEnvironment('PAO_E2E_PROVIDER_ID');
const _providerName = String.fromEnvironment('PAO_E2E_PROVIDER_NAME');

/// The Level 1 items, in the order the review lists them.
const List<ItemType> _level1 = [
  ItemType.nid,
  ItemType.selfie,
  ItemType.policeClearance,
  ItemType.address,
  ItemType.emergencyContact,
  ItemType.serviceArea,
  ItemType.codeOfConduct,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a verifier signs in with TOTP, reviews the queue and approves '
      'a provider to Level 1', (tester) async {
    final services = webServices();
    await tester.pumpWidget(PaoApp(services: services));
    await signInWithTotp(
      tester,
      email: 'verifier@pao.bd',
      password: const String.fromEnvironment('PAO_E2E_ADMIN_PASSWORD'),
      knownSecret: const String.fromEnvironment('PAO_E2E_VERIFIER_SECRET'),
    );

    await tapText(tester, 'Verification');
    await pumpUntil(tester, find.text('Verification queue'));
    await tapText(tester, _providerName);
    await pumpUntil(tester, find.text('Level 0 · Registered'));
    for (final item in _level1) {
      // Each item card is keyed by its type; pending ones are listed first,
      // so the next one is near the top of the items column.
      final approve = find.descendant(
        of: find.byKey(ValueKey(item)),
        matching: find.widgetWithText(PaoButton, 'Approve'),
      );
      await tester.fling(
        find.byType(Scrollable).last,
        const Offset(0, 2000),
        3000,
      );
      await tapOn(tester, approve);
      // A decided item loses its buttons and moves below the pending ones.
      await _gone(tester, approve);
    }
    await pumpUntil(tester, find.text('Level 1 · Verified'));

    final review = await services.api.get<Map<String, Object?>>(
      '/v1/admin/verifications/$_providerId',
    );
    expect(review.data!['level'], 1);
  });
}

Future<void> _gone(WidgetTester tester, Finder finder) async {
  final end = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isNotEmpty) {
    if (DateTime.now().isAfter(end)) fail('$finder is still shown');
    await tester.pump(const Duration(milliseconds: 100));
  }
}
