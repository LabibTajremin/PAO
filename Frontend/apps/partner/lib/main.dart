import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/app.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_ui/pao_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startErrorReporting();
  final sessions = SessionManager(SecureSessionStore());
  late final PermissionService permissions;
  final api = createApiClient(
    Env.fromDefines(),
    sessions,
    onRefreshed: () => unawaited(permissions.load()),
  );
  permissions = PermissionService(api);
  final prefs = await Prefs.open();
  final services = AppServices(
    sessions: sessions,
    permissions: permissions,
    locale: LocaleController(
      Locale(prefs.string(Prefs.languageKey) ?? PaoLocales.bangla.languageCode),
    ),
    api: api,
    prefs: prefs,
    online: ConnectivityWatcher(),
    location: DeviceLocationService(),
    launcher: Launcher(),
    photos: PhotoSource(),
    push: await _push(),
    look: AppLookService(api, await FileLookStore.support(), app: 'partner'),
  );
  // The cached look shows at once; the network check must not delay launch.
  unawaited(services.look.start());
  // The opening plays while the session loads; routing starts once it has.
  await precacheOpening();
  runApp(
    PaoApp(
      services: services,
      ready: _load(services),
      lowEnd: await isLowEndDevice(),
    ),
  );
}

Future<void> _load(AppServices services) async {
  await services.sessions.restore();
  if (services.sessions.signedIn) {
    // Offline at launch is fine: the guards re-check once these load.
    await Future.wait([services.permissions.load(), services.gate.load()])
        .catchError((Object _) => <void>[]);
  }
}

/// FCM is configured with `--dart-define`; without it the app runs without
/// push.
Future<PushService> _push() async {
  const apiKey = String.fromEnvironment('PAO_FCM_API_KEY');
  if (apiKey.isEmpty) return const NoPushService();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: apiKey,
      appId: String.fromEnvironment('PAO_FCM_APP_ID'),
      messagingSenderId: String.fromEnvironment('PAO_FCM_SENDER_ID'),
      projectId: String.fromEnvironment('PAO_FCM_PROJECT_ID'),
    ),
  );
  return FcmPushService(
    FirebaseMessaging.instance,
    local: PluginLocalNotifier.system(),
    showForeground: defaultTargetPlatform == TargetPlatform.android,
  );
}
