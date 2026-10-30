import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/account/domain/account_repository.dart';

/// Account deletion: the explanation (C29), the code (C61) and done (C62).
class DeleteAccountState {
  /// Creates the state.
  const DeleteAccountState({
    this.phone,
    this.code = '',
    this.busy = false,
    this.failure,
    this.deleted = false,
  });

  /// Where the code was sent; null until it is.
  final String? phone;

  /// The code typed so far.
  final String code;

  /// A request is running.
  final bool busy;

  /// Why the last request failed.
  final AppFailure? failure;

  /// The account is gone.
  final bool deleted;

  /// Whether a full code was typed.
  bool get codeComplete => code.length == 6;

  /// A copy with changes; [failure] is replaced, not kept.
  DeleteAccountState copyWith({
    String? phone,
    String? code,
    bool busy = false,
    AppFailure? failure,
    bool deleted = false,
  }) => DeleteAccountState(
    phone: phone ?? this.phone,
    code: code ?? this.code,
    busy: busy,
    failure: failure,
    deleted: deleted,
  );
}

/// Requests the confirmation code and deletes the account with it.
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  /// Creates the cubit.
  DeleteAccountCubit(this._repo) : super(const DeleteAccountState());

  final DeleteAccountRepository _repo;

  /// Sends a code (again).
  Future<void> requestCode() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    String? phone;
    final failure = await attempt(
      () async => phone = await _repo.requestCode(),
    );
    emit(state.copyWith(phone: phone, failure: failure));
  }

  /// Records the typed [code].
  void typed(String code) => emit(state.copyWith(code: code));

  /// Deletes the account with the typed code.
  Future<void> confirm() async {
    if (state.busy || !state.codeComplete) return;
    emit(state.copyWith(busy: true));
    final failure = await attempt(() => _repo.delete(state.code));
    emit(state.copyWith(failure: failure, deleted: failure == null));
  }
}
