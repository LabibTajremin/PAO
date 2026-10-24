import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/profile/presentation/documents_page.dart';
import 'package:pao_partner/features/profile/presentation/help_page.dart';
import 'package:pao_partner/features/profile/presentation/language_page.dart';
import 'package:pao_partner/features/profile/presentation/level_page.dart';
import 'package:pao_partner/features/profile/presentation/profile_page.dart';
import 'package:pao_partner/features/profile/presentation/public_profile_page.dart';
import 'package:pao_partner/features/profile/presentation/reviews_page.dart';
import 'package:pao_partner/features/profile/presentation/services_page.dart';

/// The profile tab (M28) and its sub-pages (M29–M35), shown over the tabs.
GoRoute profileRoute(AppServices s, GlobalKey<NavigatorState> root) {
  GoRoute sub(String path, Widget page) =>
      GoRoute(path: path, parentNavigatorKey: root, builder: (_, _) => page);
  return GoRoute(
    path: Routes.profile,
    builder: (_, _) => ProfilePage(services: s),
    routes: [
      sub('public', PublicProfilePage(services: s)),
      sub('reviews', ReviewsPage(services: s)),
      sub('documents', DocumentsPage(services: s)),
      sub('level', LevelPage(services: s)),
      sub('services', ServicesPage(services: s)),
      sub('language', LanguagePage(services: s)),
      sub('help', HelpPage(services: s)),
    ],
  );
}
