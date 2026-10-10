import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/features/onboarding/presentation/splash_page.dart';

import '../../support/harness.dart';

void main() {
  testWidgets('splash renders', (tester) async {
    final h = await Harness.create();
    await pumpPage(tester, SplashPage(services: h.services));
    expect(find.byType(SplashPage), findsOneWidget);
  });
}
