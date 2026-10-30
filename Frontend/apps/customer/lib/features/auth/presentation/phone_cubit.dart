import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/auth/domain/auth_repository.dart';

/// Phone entry (C03).
class PhoneState {
  /// Creates the state.
  const PhoneState({
    this.sending = false,
    this.invalid = false,
    this.failure,
    this.sentTo,
  });

  /// A code request is in flight.
  final bool sending;

  /// The number is not a Bangladeshi mobile number.
  final bool invalid;

  /// Why the request failed.
  final AppFailure? failure;

  /// Normalised number a code was sent to; the page moves on to C04.
  final String? sentTo;
}

/// Validates the number and asks for a code.
class PhoneCubit extends Cubit<PhoneState> {
  /// Creates the cubit.
  PhoneCubit(this._repo) : super(const PhoneState());

  final AuthRepository _repo;

  /// Sends a code to [input] if it is a valid number.
  Future<void> submit(String input) async {
    final phone = normalisePhone(input);
    if (phone == null) return emit(const PhoneState(invalid: true));
    emit(const PhoneState(sending: true));
    final failure = await attempt(() => _repo.requestCode(phone));
    emit(PhoneState(failure: failure, sentTo: failure == null ? phone : null));
  }
}
