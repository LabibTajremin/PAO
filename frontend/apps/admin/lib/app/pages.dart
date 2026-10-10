import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/auth/presentation/login_page.dart';
import 'package:pao_admin/features/auth/presentation/password_page.dart';
import 'package:pao_admin/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_admin/features/bookings/presentation/bookings_page.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_detail_page.dart';
import 'package:pao_admin/features/complaints/presentation/complaints_page.dart';
import 'package:pao_admin/features/customers/presentation/customer_detail_page.dart';
import 'package:pao_admin/features/customers/presentation/customers_page.dart';
import 'package:pao_admin/features/providers/presentation/provider_detail_page.dart';
import 'package:pao_admin/features/providers/presentation/providers_page.dart';
import 'package:pao_ui/pao_ui.dart';

String _id(GoRouterState state) => state.pathParameters['id']!;

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
  _page(Routes.providers, (_) => ProvidersPage(services: s)),
  _page('/providers/:id', (st) => ProviderDetailPage(services: s, id: _id(st))),
  _page(Routes.customers, (_) => CustomersPage(services: s)),
  _page('/customers/:id', (st) => CustomerDetailPage(services: s, id: _id(st))),
  _page(Routes.bookings, (_) => BookingsPage(services: s)),
  _page('/bookings/:id', (st) => BookingDetailPage(services: s, id: _id(st))),
  _page(Routes.complaints, (_) => ComplaintsPage(services: s)),
  _page(
    '/complaints/:id',
    (st) => ComplaintDetailPage(services: s, id: _id(st)),
  ),
  _page(Routes.settings, (_) => const PlaceholderPage(title: 'A12')),
  _page('/settings/:tab', (_) => const PlaceholderPage(title: 'A12')),
];
