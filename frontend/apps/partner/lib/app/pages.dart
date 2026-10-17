import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
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
import 'package:pao_partner/features/onboarding/presentation/splash_page.dart';
import 'package:pao_partner/features/profile/presentation/profile_routes.dart';
import 'package:pao_partner/features/requests/presentation/request_page.dart';
import 'package:pao_partner/features/verification/presentation/verification_page.dart';
import 'package:pao_ui/pao_ui.dart';

GoRoute _page(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(path: path, builder: (_, state) => build(state));

/// Splash, onboarding, sign-in and the verification gate.
List<RouteBase> entryRoutes(AppServices s) => [
  _page(Routes.splash, (_) => SplashPage(services: s)),
  _page(Routes.onboarding, (_) => OnboardingPage(services: s)),
  _page(Routes.phone, (_) => PhonePage(services: s)),
  _page(
    Routes.otp,
    (st) => OtpPage(services: s, phone: st.uri.queryParameters['phone'] ?? ''),
  ),
  GoRoute(
    path: Routes.welcomeBack,
    builder: (context, _) => Scaffold(
      body: PaoSessionExpiredView(onSignIn: () => context.go(Routes.phone)),
    ),
  ),
  _page(Routes.denied, (_) => const Scaffold(body: PaoAccessDeniedView())),
  _page(
    Routes.enrol,
    (st) => EnrolmentPage(services: s, step: st.pathParameters['step']!),
  ),
  _page(Routes.verification, (_) => VerificationPage(services: s)),
  _page(Routes.notifications, (_) => NotificationsPage(services: s)),
];

/// Full-screen job screens opened over the tabs.
List<RouteBase> workRoutes(AppServices s) {
  GoRoute job(String part, Widget Function(String id) build) =>
      _page('/jobs/:id/$part', (st) => build(st.pathParameters['id']!));
  return [
    _page(
      Routes.request,
      (st) => RequestPage(services: s, bookingId: st.pathParameters['id']!),
    ),
    job('live', (id) => LiveJobPage(services: s, bookingId: id)),
    job('start', (id) => StartCodePage(services: s, bookingId: id)),
    job('extras', (id) => ExtrasPage(services: s, bookingId: id)),
    job('complete', (id) => CompletePage(services: s, bookingId: id)),
    job('rate', (id) => RateCustomerPage(services: s, bookingId: id)),
    job('report', (id) => ReportPage(services: s, bookingId: id)),
  ];
}

/// The four bottom-navigation tabs.
List<StatefulShellBranch> shellBranches(
  AppServices s,
  GlobalKey<NavigatorState> root,
) => [
  StatefulShellBranch(
    routes: [_page(Routes.home, (_) => HomePage(services: s))],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: Routes.jobs,
        builder: (_, _) => JobsPage(services: s),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: root,
            builder: (_, st) =>
                JobDetailPage(services: s, bookingId: st.pathParameters['id']!),
          ),
        ],
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [_page(Routes.earnings, (_) => EarningsPage(services: s))],
  ),
  StatefulShellBranch(routes: [profileRoute(s, root)]),
];
