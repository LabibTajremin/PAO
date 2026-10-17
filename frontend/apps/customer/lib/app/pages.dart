import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/discovery_routes.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/account/presentation/account_routes.dart';
import 'package:pao_customer/features/auth/presentation/otp_page.dart';
import 'package:pao_customer/features/auth/presentation/phone_page.dart';
import 'package:pao_customer/features/auth/presentation/profile_setup_page.dart';
import 'package:pao_customer/features/booking/presentation/confirmed_page.dart';
import 'package:pao_customer/features/booking/presentation/setup_page.dart';
import 'package:pao_customer/features/booking/presentation/waiting_page.dart';
import 'package:pao_customer/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_customer/features/bookings/presentation/bookings_page.dart';
import 'package:pao_customer/features/bookings/presentation/receipt_page.dart';
import 'package:pao_customer/features/cancel/presentation/cancel_page.dart';
import 'package:pao_customer/features/home/presentation/home_page.dart';
import 'package:pao_customer/features/live/presentation/completed_page.dart';
import 'package:pao_customer/features/live/presentation/extras_page.dart';
import 'package:pao_customer/features/live/presentation/live_page.dart';
import 'package:pao_customer/features/location/presentation/address_page.dart';
import 'package:pao_customer/features/notifications/presentation/notifications_page.dart';
import 'package:pao_customer/features/onboarding/presentation/onboarding_page.dart';
import 'package:pao_customer/features/onboarding/presentation/splash_page.dart';
import 'package:pao_customer/features/rating/presentation/rating_page.dart';
import 'package:pao_customer/features/report/presentation/report_page.dart';
import 'package:pao_customer/shared/booking_draft.dart';
import 'package:pao_ui/pao_ui.dart';

GoRoute _page(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(path: path, builder: (_, state) => build(state));

/// Splash, onboarding, sign-in and set-up.
List<RouteBase> entryRoutes(AppServices s) => [
  _page(Routes.splash, (_) => SplashPage(services: s)),
  _page(Routes.onboarding, (_) => OnboardingPage(services: s)),
  _page(Routes.phone, (_) => PhonePage(services: s)),
  _page(
    Routes.otp,
    (st) => OtpPage(services: s, phone: st.uri.queryParameters['phone'] ?? ''),
  ),
  _page(Routes.profileSetup, (_) => ProfileSetupPage(services: s)),
  _page(Routes.location, (_) => AddressPage(services: s, onboarding: true)),
  GoRoute(
    path: Routes.welcomeBack,
    builder: (context, _) => Scaffold(
      body: PaoSessionExpiredView(onSignIn: () => context.go(Routes.phone)),
    ),
  ),
  _page(Routes.denied, (_) => const Scaffold(body: PaoAccessDeniedView())),
  ...publicAccountRoutes(),
  ...discoveryRoutes(s),
  _page(
    Routes.book,
    (st) => SetupPage(
      services: s,
      draft: BookingDraft.fromQuery(st.uri.queryParameters),
    ),
  ),
];

/// Full-screen booking screens opened over the tabs.
List<RouteBase> bookingRoutes(AppServices s) {
  GoRoute booking(String part, Widget Function(String id) build) =>
      _page('/bookings/:id/$part', (st) => build(st.pathParameters['id']!));
  return [
    booking('waiting', (id) => WaitingPage(services: s, bookingId: id)),
    booking('confirmed', (id) => ConfirmedPage(services: s, bookingId: id)),
    booking('live', (id) => LivePage(services: s, bookingId: id)),
    booking('extras', (id) => ExtrasPage(services: s, bookingId: id)),
    booking('cancel', (id) => CancelPage(services: s, bookingId: id)),
    booking('completed', (id) => CompletedPage(services: s, bookingId: id)),
    booking('rate', (id) => RatingPage(services: s, bookingId: id)),
    booking('receipt', (id) => ReceiptPage(services: s, bookingId: id)),
    booking('report', (id) => ReportPage(services: s, bookingId: id)),
  ];
}

/// The four bottom-navigation tabs: Home, Bookings, Notifications, Account.
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
        path: Routes.bookings,
        builder: (_, _) => BookingsPage(services: s),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: root,
            builder: (_, st) => BookingDetailPage(
              services: s,
              bookingId: st.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      _page(Routes.notifications, (_) => NotificationsPage(services: s)),
    ],
  ),
  StatefulShellBranch(routes: [accountRoute(s, root)]),
];
