import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/pages.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/app/shell.dart';

/// Builds the partner router: the sign-in guard first, then the verification
/// gate for signed-in providers.
GoRouter partnerRouter(AppServices s, {String initial = Routes.splash}) {
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
        cleared: s.gate.cleared,
        location: location,
        allowed: Routes.beforeLevel1,
        gate: Routes.verification,
      );
    },
    routes: [
      ...entryRoutes(s),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => PartnerShell(shell: shell),
        branches: shellBranches(s, root),
      ),
      ...workRoutes(s),
    ],
  );
}
