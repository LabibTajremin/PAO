import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/auth/domain/auth_repository.dart';

/// Stores the tokens, then loads permissions and the profile gate so the
/// router sends a new customer to profile set-up.
Future<void> startSession(AppServices services, SignedIn tokens) async {
  await services.sessions.signIn(
    Session(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken),
  );
  await Future.wait([services.permissions.load(), services.gate.load()]);
}
