import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/auth/domain/admin_auth_repository.dart';
import 'package:pao_core/pao_core.dart';

/// Login and 2FA (A01).
class LoginState {
  /// Creates the state.
  const LoginState({this.challenge, this.busy = false, this.failure});

  /// Set once the password is accepted; the page then asks for the code.
  final LoginChallenge? challenge;

  /// A request is in flight.
  final bool busy;

  /// Why the last step failed.
  final AppFailure? failure;
}

/// Runs the two login steps.
class LoginCubit extends Cubit<LoginState> {
  /// Creates the cubit; [onSignedIn] stores the token.
  LoginCubit(this._repo, {required this.onSignedIn})
    : super(const LoginState());

  final AdminAuthRepository _repo;

  /// Starts the session; told whether the password must be replaced first.
  final Future<void> Function(String token, {required bool mustChange})
  onSignedIn;

  /// Checks the email and password.
  Future<void> login(String email, String password) async {
    emit(const LoginState(busy: true));
    try {
      emit(LoginState(challenge: await _repo.login(email, password)));
    } on Object catch (e) {
      emit(LoginState(failure: AppFailure.from(e)));
    }
  }

  /// Answers the challenge with the authenticator [code].
  Future<void> verify(String code) async {
    final challenge = state.challenge!;
    emit(LoginState(challenge: challenge, busy: true));
    final failure = await attempt(() async {
      final token = await _repo.verify(challenge.id, code);
      await onSignedIn(token, mustChange: challenge.mustChangePassword);
    });
    if (!isClosed) emit(LoginState(challenge: challenge, failure: failure));
  }

  /// Goes back to the password step, e.g. to use another account.
  void restart() => emit(const LoginState());
}
