import 'package:dio/dio.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Starts a session from an access token, then loads what the admin may see.
Future<void> startSession(AppServices services, String accessToken) async {
  await services.sessions.signIn(Session(accessToken: accessToken));
  await services.permissions.load();
}

/// Reopens the session after a page reload: the access token was only in
/// memory, but the browser still holds the HttpOnly refresh cookie.
Future<void> restoreSession(AppServices services) async {
  try {
    final res = await AuthApi(services.api)
        .refreshToken(refreshRequest: RefreshRequest());
    await startSession(services, res.data!.accessToken);
  } on DioException {
    return;
  }
}

/// Ends the session here and clears the refresh cookie on the server.
Future<void> signOut(AppServices services) async {
  // Offline or already expired: signing out locally is still right.
  await attempt(() => AuthApi(services.api).logout());
  services.permissions.clear();
  await services.sessions.signOut();
}
