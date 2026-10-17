import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';

/// Signs the customer out of this device (C30) and forgets what the app
/// loaded for them, so the router returns to sign-in. A deleted account
/// skips the [remote] call: its tokens are already revoked.
Future<void> signOut(AppServices services, {bool remote = true}) async {
  // A failed call (e.g. offline) must not keep the customer signed in here;
  // the server session then simply expires with its refresh token.
  if (remote) await attempt(() => AuthApi(services.api).logout());
  services.permissions.clear();
  services.gate.clear();
  await services.sessions.signOut();
}
