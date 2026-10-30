import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/account/presentation/account_deleted_page.dart';
import 'package:pao_customer/features/account/presentation/account_page.dart';
import 'package:pao_customer/features/account/presentation/addresses_page.dart';
import 'package:pao_customer/features/account/presentation/delete_account_page.dart';
import 'package:pao_customer/features/account/presentation/edit_profile_page.dart';
import 'package:pao_customer/features/account/presentation/help_page.dart';
import 'package:pao_customer/features/account/presentation/language_page.dart';
import 'package:pao_customer/features/account/presentation/legal_page.dart';

/// The account tab (C22) and its sub-pages (C23–C29), shown over the tabs.
GoRoute accountRoute(AppServices s, GlobalKey<NavigatorState> root) {
  GoRoute sub(String path, Widget page) =>
      GoRoute(path: path, parentNavigatorKey: root, builder: (_, _) => page);
  return GoRoute(
    path: Routes.account,
    builder: (_, _) => AccountPage(services: s),
    routes: [
      sub('profile', EditProfilePage(services: s)),
      sub('addresses', AddressesPage(services: s)),
      sub('language', LanguagePage(services: s)),
      sub('help', HelpPage(services: s)),
      sub('delete', DeleteAccountPage(services: s)),
    ],
  );
}

/// Account screens open without signing in: terms (C28) and goodbye (C62).
List<RouteBase> publicAccountRoutes() => [
  GoRoute(path: Routes.legal, builder: (_, _) => const LegalPage()),
  GoRoute(
    path: Routes.accountDeleted,
    builder: (_, _) => const AccountDeletedPage(),
  ),
];
