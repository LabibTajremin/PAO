import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/pages.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/app/shell.dart';
import 'package:pao_core/pao_core.dart';

/// Builds the admin router: signed-out admins reach only login, and each
/// screen needs its screen ID in the admin's permissions.
GoRouter adminRouter(AppServices s, {String initial = Routes.dashboard}) {
  final guard = RouteGuard(
    sessions: s.sessions,
    permissions: s.permissions,
    paths: const GuardPaths(
      home: Routes.dashboard,
      signIn: Routes.login,
      expired: Routes.welcomeBack,
      denied: Routes.denied,
    ),
    screens: Routes.screens,
    public: Routes.public,
  );
  return GoRouter(
    initialLocation: initial,
    refreshListenable: Listenable.merge([
      s.sessions,
      s.permissions,
      s.mustChangePassword,
    ]),
    redirect: (_, state) {
      final location = state.uri.toString();
      final signIn = guard.redirect(location);
      if (signIn != null || !s.sessions.signedIn) return signIn;
      return passwordGate(
        mustChange: s.mustChangePassword.value,
        path: state.uri.path,
      );
    },
    routes: [
      ...entryRoutes(s),
      ShellRoute(
        builder: (_, state, child) =>
            AdminShell(services: s, location: state.uri.path, child: child),
        routes: consoleRoutes(s),
      ),
    ],
  );
}

/// Keeps an admin on the password page until the temporary password is
/// replaced, and sends them on once it is.
String? passwordGate({required bool mustChange, required String path}) {
  if (mustChange) return path == Routes.password ? null : Routes.password;
  return path == Routes.password ? Routes.dashboard : null;
}
