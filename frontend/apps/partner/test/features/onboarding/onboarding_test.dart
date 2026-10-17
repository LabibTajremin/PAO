import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/auth/presentation/phone_page.dart';
import 'package:pao_partner/features/onboarding/presentation/onboarding_page.dart';
import 'package:pao_partner/features/onboarding/presentation/splash_page.dart';

import '../../support/harness.dart';

void main() {
  testWidgets('the first launch goes from splash to onboarding', (
    tester,
  ) async {
    final h = await Harness.create();
    await h.pumpApp(tester, Routes.splash);
    expect(find.byType(OnboardingPage), findsOne);
  });

  testWidgets('later launches go home, where the guard asks to sign in', (
    tester,
  ) async {
    final h = await Harness.create();
    await h.services.prefs.setFlag(Prefs.onboardedKey, value: true);
    await h.pumpApp(tester, Routes.splash);
    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(PhonePage), findsOne);
  });

  testWidgets('slides, a language choice, then sign-in', (tester) async {
    final h = await Harness.create();
    await h.pumpApp(tester, Routes.onboarding);
    expect(find.text('Get jobs near you'), findsOne);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Fixed prices, cash in hand'), findsOne);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Verified and trusted'), findsOne);
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(find.text('যাচাইকৃত ও বিশ্বস্ত'), findsOne);
    await tester.tap(find.text('শুরু করুন'));
    await h.settle(tester);
    expect(find.byType(PhonePage), findsOne);
    expect(h.services.prefs.string(Prefs.languageKey), 'bn');
    expect(h.services.prefs.flag(Prefs.onboardedKey), isTrue);
  });

  testWidgets('skip keeps the current language', (tester) async {
    final h = await Harness.create();
    await h.pumpApp(tester, Routes.onboarding);
    await tester.tap(find.text('Skip'));
    await h.settle(tester);
    expect(find.byType(PhonePage), findsOne);
    expect(h.services.prefs.string(Prefs.languageKey), 'en');
  });
}
