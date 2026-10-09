import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// Long-lived services shared by every screen of the app.
class AppServices {
  /// Bundles the services.
  const AppServices({
    required this.sessions,
    required this.permissions,
    required this.locale,
  });

  /// The signed-in session.
  final SessionManager sessions;

  /// What the account may see and do.
  final PermissionService permissions;

  /// The language the app shows.
  final LocaleController locale;
}
