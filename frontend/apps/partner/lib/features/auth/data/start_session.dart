import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/auth/domain/auth_repository.dart';

/// Stores the tokens, then loads permissions and the verification gate so the
/// router sends the provider to the right screen.
Future<void> startSession(AppServices services, SignedIn tokens) async {
  await services.sessions.signIn(
    Session(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken),
  );
  await Future.wait([services.permissions.load(), services.gate.load()]);
}
