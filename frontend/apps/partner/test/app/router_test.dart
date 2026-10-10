import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/auth/presentation/otp_page.dart';
import 'package:pao_partner/features/auth/presentation/phone_page.dart';
import 'package:pao_partner/features/earnings/presentation/earnings_page.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_page.dart';
import 'package:pao_partner/features/home/presentation/home_page.dart';
import 'package:pao_partner/features/job/presentation/complete_page.dart';
import 'package:pao_partner/features/job/presentation/extras_page.dart';
import 'package:pao_partner/features/job/presentation/live_job_page.dart';
import 'package:pao_partner/features/job/presentation/rate_customer_page.dart';
import 'package:pao_partner/features/job/presentation/start_code_page.dart';
import 'package:pao_partner/features/jobs/presentation/job_detail_page.dart';
import 'package:pao_partner/features/jobs/presentation/jobs_page.dart';
import 'package:pao_partner/features/jobs/presentation/report_page.dart';
import 'package:pao_partner/features/notifications/presentation/notifications_page.dart';
import 'package:pao_partner/features/onboarding/presentation/onboarding_page.dart';
import 'package:pao_partner/features/profile/presentation/documents_page.dart';
import 'package:pao_partner/features/profile/presentation/help_page.dart';
import 'package:pao_partner/features/profile/presentation/language_page.dart';
import 'package:pao_partner/features/profile/presentation/level_page.dart';
import 'package:pao_partner/features/profile/presentation/profile_page.dart';
import 'package:pao_partner/features/profile/presentation/public_profile_page.dart';
import 'package:pao_partner/features/profile/presentation/reviews_page.dart';
import 'package:pao_partner/features/profile/presentation/services_page.dart';
import 'package:pao_partner/features/requests/presentation/request_page.dart';
import 'package:pao_partner/features/verification/presentation/verification_page.dart';

import '../support/harness.dart';

void main() {
  testWidgets('signed-out providers land on phone entry', (tester) async {
    final h = await Harness.create();
    await h.pumpApp(tester);
    expect(find.byType(PhonePage), findsOneWidget);
  });

  testWidgets('below Level 1 only enrolment and verification open', (
    tester,
  ) async {
    final h = await Harness.create();
    await h.signIn(tester, cleared: false);
    await h.pumpApp(tester);
    expect(find.byType(VerificationPage), findsOneWidget);
    await h.go(tester, Routes.enrolStep('personal'));
    expect(find.byType(EnrolmentPage), findsOneWidget);
  });

  testWidgets('a cleared provider reaches every screen', (tester) async {
    final h = await Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester);
    final pages = <String, Type>{
      Routes.home: HomePage,
      Routes.onboarding: OnboardingPage,
      '${Routes.otp}?phone=01712345678': OtpPage,
      Routes.verification: VerificationPage,
      Routes.notifications: NotificationsPage,
      Routes.requestOf('b1'): RequestPage,
      Routes.job('b1', 'live'): LiveJobPage,
      Routes.job('b1', 'start'): StartCodePage,
      Routes.job('b1', 'extras'): ExtrasPage,
      Routes.job('b1', 'complete'): CompletePage,
      Routes.job('b1', 'rate'): RateCustomerPage,
      Routes.job('b1', 'report'): ReportPage,
      Routes.jobs: JobsPage,
      Routes.job('b1'): JobDetailPage,
      Routes.earnings: EarningsPage,
      Routes.profile: ProfilePage,
      Routes.profilePage('public'): PublicProfilePage,
      Routes.profilePage('reviews'): ReviewsPage,
      Routes.profilePage('documents'): DocumentsPage,
      Routes.profilePage('level'): LevelPage,
      Routes.profilePage('services'): ServicesPage,
      Routes.profilePage('language'): LanguagePage,
      Routes.profilePage('help'): HelpPage,
    };
    for (final MapEntry(key: path, value: type) in pages.entries) {
      await h.go(tester, path);
      expect(find.byType(type), findsOneWidget, reason: path);
    }
    await h.go(tester, Routes.otp);
    expect(find.byType(OtpPage), findsOneWidget);
    await h.go(tester, Routes.home);
    expect(find.byType(HomePage), findsOneWidget);
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
    expect(find.byType(PhonePage), findsOneWidget);
  });
}
