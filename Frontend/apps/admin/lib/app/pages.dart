import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/auth/presentation/login_page.dart';
import 'package:pao_admin/features/auth/presentation/password_page.dart';
import 'package:pao_admin/features/billing/data/api_billing_repository.dart';
import 'package:pao_admin/features/billing/domain/billing_repository.dart';
import 'package:pao_admin/features/billing/presentation/ledger_page.dart';
import 'package:pao_admin/features/billing/presentation/payments_page.dart';
import 'package:pao_admin/features/bookings/presentation/booking_detail_page.dart';
import 'package:pao_admin/features/bookings/presentation/bookings_page.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_page.dart';
import 'package:pao_admin/features/catalog/presentation/service_editor_page.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_detail_page.dart';
import 'package:pao_admin/features/complaints/presentation/complaints_page.dart';
import 'package:pao_admin/features/customers/presentation/customer_detail_page.dart';
import 'package:pao_admin/features/customers/presentation/customers_page.dart';
import 'package:pao_admin/features/dashboard/presentation/dashboard_page.dart';
import 'package:pao_admin/features/level2/data/api_level2_repository.dart';
import 'package:pao_admin/features/level2/presentation/level2_page.dart';
import 'package:pao_admin/features/providers/presentation/provider_detail_page.dart';
import 'package:pao_admin/features/providers/presentation/providers_page.dart';
import 'package:pao_admin/features/settings/presentation/settings_page.dart';
import 'package:pao_admin/features/verification/data/api_verification_repository.dart';
import 'package:pao_admin/features/verification/presentation/queue_page.dart';
import 'package:pao_admin/features/verification/presentation/review_page.dart';
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
  _page(Routes.dashboard, (_) => DashboardPage(services: s)),
  _page(Routes.catalog, (_) => CatalogPage(services: s)),
  _page(
    Routes.service,
    (state) => ServiceEditorPage(
      services: s,
      id: state.pathParameters['id']!,
      categoryId: state.uri.queryParameters['category'],
    ),
  ),
  _page(
    Routes.verification,
    (_) => QueuePage(repo: ApiVerificationRepository(s.api)),
  ),
  _page(Routes.review, (state) {
    final id = state.pathParameters['providerId']!;
    return ReviewPage(
      key: ValueKey(id),
      repo: ApiVerificationRepository(s.api),
      providerId: id,
      permissions: s.permissions,
    );
  }),
  _page(
    Routes.level2,
    (_) => Level2Page(
      repo: ApiLevel2Repository(s.api, s.permissions),
      permissions: s.permissions,
      now: s.now,
    ),
  ),
  ...peopleRoutes(s),
  ...billingRoutes(s),
  _page(Routes.settings, (_) => SettingsPage(services: s)),
  _page(
    '/settings/:tab',
    (state) => SettingsPage(services: s, tab: state.pathParameters['tab']!),
  ),
];

/// Providers, customers, bookings and complaints, each a list and a detail.
List<RouteBase> peopleRoutes(AppServices s) => [
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
];

/// The payments queue and merchant ledgers, for admins with
/// `billing:manage`; the routes have no screen ID, so the permission gates
/// them here.
List<RouteBase> billingRoutes(AppServices s) {
  Widget gated(Widget page) =>
      s.permissions.can(billingPermission) ? page : const PaoAccessDeniedView();
  return [
    _page(
      Routes.payments,
      (_) => gated(PaymentsPage(repo: ApiBillingRepository(s.api))),
    ),
    _page(
      Routes.ledger,
      (st) => gated(
        LedgerPage(
          repo: ApiBillingRepository(s.api),
          providerId: st.pathParameters['providerId']!,
        ),
      ),
    ),
  ];
}
