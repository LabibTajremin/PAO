import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/discovery_routes.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/auth/presentation/otp_page.dart';
import 'package:pao_customer/features/auth/presentation/phone_page.dart';
import 'package:pao_customer/features/auth/presentation/profile_setup_page.dart';
import 'package:pao_customer/features/home/presentation/home_page.dart';
import 'package:pao_customer/features/location/presentation/address_page.dart';
import 'package:pao_customer/features/onboarding/presentation/onboarding_page.dart';
import 'package:pao_customer/features/onboarding/presentation/splash_page.dart';
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
  ...discoveryRoutes(s),
  _page(Routes.book, (_) => const PlaceholderPage(title: 'C12')),
];

/// Full-screen booking screens opened over the tabs.
List<RouteBase> bookingRoutes(AppServices s) {
  GoRoute booking(String part, Widget Function(String id) build) =>
      _page('/bookings/:id/$part', (st) => build(st.pathParameters['id']!));
  return [
    booking('waiting', (_) => const PlaceholderPage(title: 'C13')),
    booking('confirmed', (_) => const PlaceholderPage(title: 'C48')),
    booking('live', (_) => const PlaceholderPage(title: 'C14')),
    booking('extras', (_) => const PlaceholderPage(title: 'C15')),
    booking('cancel', (_) => const PlaceholderPage(title: 'C52')),
    booking('completed', (_) => const PlaceholderPage(title: 'C16')),
    booking('rate', (_) => const PlaceholderPage(title: 'C17')),
    booking('receipt', (_) => const PlaceholderPage(title: 'C64')),
    booking('report', (_) => const PlaceholderPage(title: 'C20')),
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
        builder: (_, _) => const PlaceholderPage(title: 'C18'),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: root,
            builder: (_, _) => const PlaceholderPage(title: 'C19'),
          ),
        ],
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      _page(Routes.notifications, (_) => const PlaceholderPage(title: 'C21')),
    ],
  ),
  StatefulShellBranch(routes: [_accountRoute(root)]),
];

GoRoute _accountRoute(GlobalKey<NavigatorState> root) => GoRoute(
  path: Routes.account,
  builder: (_, _) => const PlaceholderPage(title: 'C22'),
  routes: [
    GoRoute(
      path: ':page',
      parentNavigatorKey: root,
      builder: (_, st) => PlaceholderPage(title: st.pathParameters['page']!),
    ),
  ],
);
