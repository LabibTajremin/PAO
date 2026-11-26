// The motion performance run (P27, docs/guides/motion.md): on a device in
// profile mode against the e2e stack, through test_driver/perf_driver.dart.
// It lives outside integration_test/*_test.dart so the desktop journeys skip it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pao_customer/app/app.dart';
import 'package:pao_e2e/pao_e2e.dart';

import '../support/booking_ui.dart';
import '../support/stack_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final stack = StackClient.fromDefines();

  testWidgets('opening and moving between the main screens', (tester) async {
    final services = await stackServices();
    await binding.traceAction(() async {
      await tester.pumpWidget(
        PaoApp(services: services, ready: Future.value()),
      );
      await signUp(tester, stack, uniquePhone('017', 9));
      for (var i = 0; i < 5; i++) {
        await tapText(tester, 'Electrical');
        await tester.pageBack();
        await idle(tester);
      }
      await tapText(tester, 'Bookings');
      await tapText(tester, 'Account');
      await tapText(tester, 'Language');
      await tester.pageBack();
      await idle(tester);
      // The log-out question is a sheet; tapping the scrim dismisses it.
      await tapText(tester, 'Log out');
      await tester.tapAt(const Offset(8, 8));
      await idle(tester);
      await tapText(tester, 'Home');
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -600),
        2000,
      );
      await idle(tester);
    }, reportKey: 'motion');
  });
}
