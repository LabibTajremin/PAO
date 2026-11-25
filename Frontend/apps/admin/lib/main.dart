import 'dart:async';

import 'package:dio/browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:pao_admin/app/app.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_admin/features/auth/data/session_restore.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  // Plain paths (/verification) instead of /#/verification; vercel.json
  // rewrites every path to index.html so reloads and links still work.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await startErrorReporting();
  final sessions = SessionManager(MemorySessionStore());
  late final PermissionService permissions;
  final api = createApiClient(
    Env.fromDefines(),
    sessions,
    // The refresh token lives in an HttpOnly cookie the browser must send.
    adapter: BrowserHttpClientAdapter(withCredentials: true),
    onRefreshed: () => unawaited(permissions.load()),
  );
  permissions = PermissionService(api);
  final services = AppServices(
    sessions: sessions,
    permissions: permissions,
    locale: LocaleController(PaoLocales.english),
    api: api,
    themeMode: ThemeModeController(await Prefs.open()),
  );
  await restoreSession(services);
  final reduced = web.window
      .matchMedia('(prefers-reduced-motion: reduce)')
      .matches;
  runApp(PaoApp(services: services, reducedMotion: reduced));
}
