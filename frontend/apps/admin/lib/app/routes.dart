import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/home_page.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/app/sign_in_page.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Route paths of the app (docs/build/05-screens.md).
abstract final class Routes {
  /// Home (A02).
  static const home = '/home';

  /// Sign-in (A01).
  static const signIn = '/auth/sign-in';

  /// Session expired (C63).
  static const welcomeBack = '/auth/welcome-back';

  /// Role may not open a screen.
  static const denied = '/denied';
}

/// Builds the guarded router: signed-out users only reach the auth routes.
GoRouter appRouter(AppServices services) => guardedRouter(
  initialLocation: Routes.home,
  guard: RouteGuard(
    sessions: services.sessions,
    permissions: services.permissions,
    paths: const GuardPaths(
      home: Routes.home,
      signIn: Routes.signIn,
      expired: Routes.welcomeBack,
      denied: Routes.denied,
    ),
    screens: const {Routes.home: 'A02'},
    public: const {Routes.signIn, Routes.welcomeBack},
  ),
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (_, _) => HomePage(services: services),
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (_, _) => SignInPage(services: services),
    ),
    GoRoute(
      path: Routes.welcomeBack,
      builder: (context, _) => Scaffold(
        body: PaoSessionExpiredView(onSignIn: () => context.go(Routes.signIn)),
      ),
    ),
    GoRoute(
      path: Routes.denied,
      builder: (_, _) => const Scaffold(body: PaoAccessDeniedView()),
    ),
  ],
);
