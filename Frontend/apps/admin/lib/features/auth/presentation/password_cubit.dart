import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/auth/domain/admin_auth_repository.dart';
import 'package:pao_core/pao_core.dart';

/// Why a new password is not accepted before sending it.
enum PasswordProblem {
  /// Shorter than [minPasswordLength].
  tooShort,

  /// The two entries differ.
  mismatch,
}

/// Replacing the temporary password (A01).
class PasswordState {
  /// Creates the state.
  const PasswordState({
    this.busy = false,
    this.problem,
    this.failure,
    this.done = false,
  });

  /// The change is in flight.
  final bool busy;

  /// A local check failed.
  final PasswordProblem? problem;

  /// Why the API refused.
  final AppFailure? failure;

  /// Changed.
  final bool done;
}

/// Checks and changes the password.
class PasswordCubit extends Cubit<PasswordState> {
  /// Creates the cubit.
  PasswordCubit(this._repo) : super(const PasswordState());

  final AdminAuthRepository _repo;

  /// Changes [current] to [next] once [next] and [repeat] agree.
  Future<void> change(String current, String next, String repeat) async {
    if (next.length < minPasswordLength) {
      return emit(const PasswordState(problem: PasswordProblem.tooShort));
    }
    if (next != repeat) {
      return emit(const PasswordState(problem: PasswordProblem.mismatch));
    }
    emit(const PasswordState(busy: true));
    final failure = await attempt(() => _repo.changePassword(current, next));
    emit(PasswordState(failure: failure, done: failure == null));
  }
}
