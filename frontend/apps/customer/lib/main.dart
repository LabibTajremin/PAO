import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/app.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/location/data/google_places.dart';
import 'package:pao_l10n/pao_l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    places: placesFromEnvironment(),
  );
  await sessions.restore();
  if (sessions.signedIn) {
    // Offline at launch is fine: the guards re-check once these load.
    await Future.wait([permissions.load(), services.gate.load()])
        .catchError((Object _) => <void>[]);
  }
  runApp(PaoApp(services: services));
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
  return FcmPushService(FirebaseMessaging.instance);
}
