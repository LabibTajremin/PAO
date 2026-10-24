import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/app/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The partner app's services against the e2e stack, wired as `main.dart`
/// wires them, except the device: no camera, GPS, push or keyring on the
/// Linux runner, so those are stand-ins and only the network and UI are real.
Future<AppServices> stackServices() async {
  SharedPreferences.setMockInitialValues({});
  final sessions = SessionManager(MemorySessionStore());
  late final PermissionService permissions;
  final api = createApiClient(
    const Env(
      apiBaseUrl: String.fromEnvironment('PAO_API_BASE_URL'),
      flavour: 'e2e',
    ),
    sessions,
    onRefreshed: () => unawaited(permissions.load()),
  );
  // Each journey is its own device with its own address, as on a real
  // network, so the per-address limit on one-time codes is not shared.
  api.interceptors.insert(0, ClientAddress());
  permissions = PermissionService(api);
  return AppServices(
    sessions: sessions,
    permissions: permissions,
    locale: LocaleController(PaoLocales.english),
    api: api,
    prefs: await Prefs.open(),
    online: ValueNotifier(true),
    location: const FixedLocation(),
    launcher: Launcher(open: (_) async => true),
    photos: StubPhotos(),
    push: const NoPushService(),
  );
}
