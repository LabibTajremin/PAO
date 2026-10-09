import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/app.dart';
import 'package:pao_partner/app/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessions = SessionManager(SecureSessionStore());
  late final PermissionService permissions;
  final dio = createApiClient(
    Env.fromDefines(),
    sessions,
    onRefreshed: () => unawaited(permissions.load()),
  );
  permissions = PermissionService(dio);
  await sessions.restore();
  if (sessions.signedIn) {
    // Offline at launch is fine: the guard re-checks once permissions load.
    await permissions.load().catchError((Object _) {});
  }
  runApp(
    PaoApp(
      services: AppServices(
        sessions: sessions,
        permissions: permissions,
        locale: LocaleController(),
      ),
    ),
  );
}
