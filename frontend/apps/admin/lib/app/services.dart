import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// Long-lived services shared by every screen of the admin panel. Feature
/// repositories are built from [api].
class AppServices {
  /// Bundles the services.
  AppServices({
    required this.sessions,
    required this.permissions,
    required this.locale,
    required this.api,
    DateTime Function()? clock,
  }) : now = clock ?? DateTime.now;

  /// The signed-in session; the access token lives only in memory.
  final SessionManager sessions;

  /// What the admin may see and do.
  final PermissionService permissions;

  /// The language the panel shows.
  final LocaleController locale;

  /// Authenticated client for the PAO API.
  final Dio api;

  /// Current time; injectable so relative dates are testable.
  final DateTime Function() now;

  /// The admin still signs in with the temporary password from the invite and
  /// must replace it before using the console.
  final ValueNotifier<bool> mustChangePassword = ValueNotifier(false);
}
