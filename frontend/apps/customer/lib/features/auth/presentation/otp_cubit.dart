import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/auth/domain/auth_repository.dart';

/// Code entry (C04, C33).
class OtpState {
  /// Creates the state.
  const OtpState({
    required this.resendIn,
    this.verifying = false,
    this.failure,
    this.done = false,
  });

  /// Seconds before another code may be requested.
  final int resendIn;

  /// The code is being checked.
  final bool verifying;

  /// Why the last action failed, e.g. `OTP_INVALID`.
  final AppFailure? failure;

  /// Signed in.
  final bool done;

  /// Whether the boxes should show the wrong-code state.
  bool get wrongCode =>
      failure?.code == 'OTP_INVALID' || failure?.code == 'OTP_EXPIRED';

  /// A copy with changes; [failure] is replaced, not kept.
  OtpState copyWith({
    int? resendIn,
    bool? verifying,
    AppFailure? failure,
    bool? done,
  }) => OtpState(
    resendIn: resendIn ?? this.resendIn,
    verifying: verifying ?? this.verifying,
    failure: failure,
    done: done ?? this.done,
  );
}

/// Checks the code, counts down to resend and signs in.
class OtpCubit extends Cubit<OtpState> {
  /// Creates the cubit; [onSignedIn] stores the session.
  OtpCubit(
    this._repo,
    this._phone, {
    required this.onSignedIn,
    int resendAfter = 30,
  }) : super(OtpState(resendIn: resendAfter)) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final AuthRepository _repo;
  final String _phone;
  late final Timer _timer;

  /// Stores the tokens once the code is right.
  final Future<void> Function(SignedIn tokens) onSignedIn;

  void _tick() {
    if (state.resendIn > 0) {
      emit(
        state.copyWith(resendIn: state.resendIn - 1, failure: state.failure),
      );
    }
  }

  /// Checks [code].
  Future<void> verify(String code) async {
    emit(state.copyWith(verifying: true));
    final failure = await attempt(
      () async => await onSignedIn(await _repo.verify(_phone, code)),
    );
    emit(
      state.copyWith(verifying: false, failure: failure, done: failure == null),
    );
  }

  /// Requests a new code once the countdown is over.
  Future<void> resend() async {
    if (state.resendIn > 0) return;
    try {
      final sent = await _repo.requestCode(_phone);
      emit(state.copyWith(resendIn: sent.resendAfter.inSeconds));
    } on Object catch (e) {
      emit(state.copyWith(failure: AppFailure.from(e)));
    }
  }

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}
