import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/auth/presentation/login_page.dart';
import 'package:pao_admin/features/auth/presentation/password_page.dart';
import 'package:pao_ui/pao_ui.dart';

GoRoute _page(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(path: path, builder: (_, state) => build(state));

/// Login, password change and the full-screen states.
List<RouteBase> entryRoutes(AppServices s) => [
  _page(Routes.login, (_) => LoginPage(services: s)),
  _page(Routes.password, (_) => PasswordPage(services: s)),
  GoRoute(
    path: Routes.welcomeBack,
    builder: (context, _) => Scaffold(
      body: PaoSessionExpiredView(onSignIn: () => context.go(Routes.login)),
    ),
  ),
  _page(Routes.denied, (_) => const Scaffold(body: PaoAccessDeniedView())),
];

/// Screens shown inside the console shell.
List<RouteBase> consoleRoutes(AppServices s) => [
  _page(Routes.dashboard, (_) => const PlaceholderPage(title: 'A02')),
  _page(Routes.catalog, (_) => const PlaceholderPage(title: 'A03')),
  _page(Routes.service, (_) => const PlaceholderPage(title: 'A04')),
  _page(Routes.verification, (_) => const PlaceholderPage(title: 'A05')),
  _page(Routes.review, (_) => const PlaceholderPage(title: 'A06')),
  _page(Routes.level2, (_) => const PlaceholderPage(title: 'A07')),
  _page(Routes.providers, (_) => const PlaceholderPage(title: 'A08')),
  _page('/providers/:id', (_) => const PlaceholderPage(title: 'A08')),
  _page(Routes.customers, (_) => const PlaceholderPage(title: 'A09')),
  _page('/customers/:id', (_) => const PlaceholderPage(title: 'A09')),
  _page(Routes.bookings, (_) => const PlaceholderPage(title: 'A10')),
  _page('/bookings/:id', (_) => const PlaceholderPage(title: 'A10')),
  _page(Routes.complaints, (_) => const PlaceholderPage(title: 'A11')),
  _page('/complaints/:id', (_) => const PlaceholderPage(title: 'A11')),
  _page(Routes.settings, (_) => const PlaceholderPage(title: 'A12')),
  _page('/settings/:tab', (_) => const PlaceholderPage(title: 'A12')),
];
