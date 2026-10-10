import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';

/// Signs the provider out of this device (M36) and forgets what the app
/// loaded for them, so the router returns to sign-in.
Future<void> signOut(AppServices services) async {
  // A failed call (e.g. offline) must not keep the provider signed in here;
  // the server session then simply expires with its refresh token.
  await attempt(() => AuthApi(services.api).logout());
  services.permissions.clear();
  services.gate.clear();
  await services.sessions.signOut();
}
