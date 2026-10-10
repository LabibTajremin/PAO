import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';

/// The set-up form (C12, C45).
class SetupState {
  /// Creates the state.
  const SetupState({
    this.view = const ViewLoading(),
    this.timing = Timing.asap,
    this.at,
    this.addressId,
    this.busy = false,
    this.failure,
    this.invalidTime = false,
    this.booking,
  });

  /// The service, provider and addresses.
  final ViewState<BookingOptions> view;

  /// ASAP or scheduled.
  final Timing timing;

  /// The scheduled start; kept when switching to ASAP and back.
  final DateTime? at;

  /// The chosen address.
  final String? addressId;

  /// The booking is being requested.
  final bool busy;

  /// Why the last request failed.
  final AppFailure? failure;

  /// Confirming found no valid scheduled start.
  final bool invalidTime;

  /// The created booking; the page moves on.
  final Booking? booking;

  /// The loaded options, if any.
  BookingOptions? get options => switch (view) {
    ViewData(:final data) => data,
    _ => null,
  };

  /// A copy with changes; [busy], [failure] and [invalidTime] are replaced,
  /// not kept, because each action starts them afresh.
  SetupState copyWith({
    ViewState<BookingOptions>? view,
    Timing? timing,
    DateTime? at,
    String? addressId,
    bool busy = false,
    AppFailure? failure,
    bool invalidTime = false,
    Booking? booking,
  }) => SetupState(
    view: view ?? this.view,
    timing: timing ?? this.timing,
    at: at ?? this.at,
    addressId: addressId ?? this.addressId,
    busy: busy,
    failure: failure,
    invalidTime: invalidTime,
    booking: booking ?? this.booking,
  );
}
