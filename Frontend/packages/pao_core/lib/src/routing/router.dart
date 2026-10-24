import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/src/routing/guard.dart';

/// A go_router that re-checks [guard] whenever the session or permissions
/// change.
GoRouter guardedRouter({
  required RouteGuard guard,
  required List<RouteBase> routes,
  String initialLocation = '/',
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: Listenable.merge([guard.sessions, guard.permissions]),
  redirect: (_, state) => guard.redirect(state.uri.toString()),
  routes: routes,
);
