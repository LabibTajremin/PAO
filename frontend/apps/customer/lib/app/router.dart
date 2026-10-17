import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/pages.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/app/shell.dart';

/// Builds the customer router: the sign-in guard first, then the profile gate
/// for new accounts.
GoRouter customerRouter(AppServices s, {String initial = Routes.splash}) {
  final guard = RouteGuard(
    sessions: s.sessions,
    permissions: s.permissions,
    paths: const GuardPaths(
      home: Routes.home,
      signIn: Routes.phone,
      expired: Routes.welcomeBack,
      denied: Routes.denied,
    ),
    screens: Routes.screens,
    public: Routes.public,
  );
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: initial,
    refreshListenable: Listenable.merge([s.sessions, s.permissions, s.gate]),
    redirect: (_, state) {
      final location = state.uri.toString();
      final signIn = guard.redirect(location);
      if (signIn != null || !s.sessions.signedIn) return signIn;
      return verificationGate(
        cleared: !s.gate.missing,
        location: location,
        allowed: Routes.beforeProfile,
        gate: Routes.profileSetup,
      );
    },
    routes: [
      ...entryRoutes(s),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => CustomerShell(shell: shell),
        branches: shellBranches(s, root),
      ),
      ...bookingRoutes(s),
    ],
  );
}
