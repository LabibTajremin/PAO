import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';

import '../support/harness.dart';

void main() {
  testWidgets('signed-out providers land on phone entry', (tester) async {
    final h = await Harness.create();
    await h.pumpApp(tester);
    expect(find.text('What is your phone number?'), findsOneWidget);
  });

  testWidgets('below Level 1 only enrolment and verification open', (
    tester,
  ) async {
    final h = await Harness.create();
    await h.signIn(tester, cleared: false);
    await h.pumpApp(tester);
    expect(find.text('VerificationPage'), findsOneWidget);
    await h.go(tester, Routes.enrolStep('personal'));
    expect(find.text('EnrolmentPage'), findsOneWidget);
  });

  testWidgets('a cleared provider reaches every screen', (tester) async {
    final h = await Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester);
    final pages = {
      Routes.home: 'HomePage',
      Routes.splash: 'SplashPage',
      Routes.onboarding: 'OnboardingPage',
      '${Routes.otp}?phone=01712345678': 'Enter the 6-digit code',
      Routes.verification: 'VerificationPage',
      Routes.notifications: 'NotificationsPage',
      Routes.requestOf('b1'): 'RequestPage',
      Routes.job('b1', 'live'): 'LiveJobPage',
      Routes.job('b1', 'start'): 'StartCodePage',
      Routes.job('b1', 'extras'): 'ExtrasPage',
      Routes.job('b1', 'complete'): 'CompletePage',
      Routes.job('b1', 'rate'): 'RateCustomerPage',
      Routes.job('b1', 'report'): 'ReportPage',
      Routes.jobs: 'JobsPage',
      Routes.job('b1'): 'JobDetailPage',
      Routes.earnings: 'EarningsPage',
      Routes.profile: 'ProfilePage',
      for (final p in [
        'public',
        'reviews',
        'documents',
        'level',
        'services',
        'language',
        'help',
      ])
        Routes.profilePage(p): '${p[0].toUpperCase()}${p.substring(1)}',
    };
    for (final MapEntry(key: path, value: title) in pages.entries) {
      await h.go(tester, path);
      expect(find.textContaining(title), findsWidgets, reason: path);
    }
    await h.go(tester, Routes.otp);
    expect(find.text('Enter the 6-digit code'), findsOneWidget);
  });

  testWidgets('tabs switch branches; denied and expired screens', (
    tester,
  ) async {
    final h = await Harness.create();
    await h.signIn(tester, screens: ['M15']);
    await h.pumpApp(tester);
    await tester.tap(find.text('Earnings'));
    await h.settle(tester);
    expect(find.text('You do not have access to this screen.'), findsOneWidget);
    await h.services.sessions.signOut(expired: true);
    await h.settle(tester);
    await tester.tap(find.text('Continue'));
    await h.settle(tester);
    expect(find.text('What is your phone number?'), findsOneWidget);
  });
}
