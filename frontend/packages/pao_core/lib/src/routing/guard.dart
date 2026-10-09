import 'package:pao_core/src/permissions.dart';
import 'package:pao_core/src/session/session.dart';

/// Paths a [RouteGuard] sends people to.
class GuardPaths {
  /// Creates the set of redirect targets.
  const GuardPaths({
    required this.home,
    required this.signIn,
    required this.expired,
    required this.denied,
  });

  /// Where signed-in users land when they open sign-in or welcome-back.
  final String home;

  /// Where signed-out users go.
  final String signIn;

  /// Where users go after their session expired (C63).
  final String expired;

  /// Where users go when their role may not open a screen.
  final String denied;
}

/// Decides go_router redirects: signed-out users reach only public routes, and
/// a route mapped to a screen ID needs that screen in the account's
/// permissions.
class RouteGuard {
  /// Creates the guard; [screens] maps route patterns like `/bookings/:id` to
  /// IDs.
  RouteGuard({
    required this.sessions,
    required this.permissions,
    required this.paths,
    this.screens = const {},
    this.public = const {},
  });

  /// Current session.
  final SessionManager sessions;

  /// Current permissions.
  final PermissionService permissions;

  /// Redirect targets.
  final GuardPaths paths;

  /// Screen ID per route pattern.
  final Map<String, String> screens;

  /// Route patterns open without signing in.
  final Set<String> public;

  /// Returns where [location] should redirect, or null to stay.
  String? redirect(String location) {
    final path = Uri.parse(location).path;
    if (sessions.signedIn && (path == paths.signIn || path == paths.expired)) {
      return paths.home;
    }
    if (public.any((p) => routeMatches(p, path))) return null;
    if (!sessions.signedIn) {
      return sessions.expired ? paths.expired : paths.signIn;
    }
    for (final MapEntry(key: pattern, value: id) in screens.entries) {
      if (routeMatches(pattern, path) && !permissions.canSee(id)) {
        return path == paths.denied ? null : paths.denied;
      }
    }
    return null;
  }
}

/// Whether [path] fits [pattern], where `:name` segments match any one segment.
bool routeMatches(String pattern, String path) {
  final want = pattern.split('/');
  final got = path.split('/');
  if (want.length != got.length) return false;
  for (var i = 0; i < want.length; i++) {
    if (!want[i].startsWith(':') && want[i] != got[i]) return false;
  }
  return true;
}

/// The partner-app gate (PRD §8.5): below Level 1, or with an expired document,
/// only the enrolment and verification routes in [allowed] are reachable.
String? verificationGate({
  required bool cleared,
  required String location,
  required Set<String> allowed,
  required String gate,
}) {
  final path = Uri.parse(location).path;
  if (cleared || allowed.any((p) => routeMatches(p, path))) return null;
  return gate;
}
