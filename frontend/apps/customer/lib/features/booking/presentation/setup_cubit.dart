import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/booking/domain/bill_line.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';
import 'package:pao_customer/features/booking/domain/schedule.dart';
import 'package:pao_customer/features/booking/presentation/setup_state.dart';
import 'package:pao_customer/shared/booking_draft.dart';

export 'package:pao_customer/features/booking/presentation/setup_state.dart';

/// Booking set-up (C12, C45, C46): timing, address and confirmation.
class SetupCubit extends Cubit<SetupState> {
  /// Creates the cubit for [_draft]; `now` is the app clock and `newKey`
  /// makes idempotency keys.
  SetupCubit(
    this._repo,
    this._draft, {
    required this._now,
    String Function()? newKey,
  }) : _newKey = newKey ?? newIdempotencyKey,
       super(const SetupState());

  final BookingRepository _repo;
  final BookingDraft _draft;
  final DateTime Function() _now;
  final String Function() _newKey;

  // The request a key was made for: retrying the same request reuses the key
  // so a lost response cannot create a second booking.
  (String request, String key)? _attempt;

  /// Loads the service, provider and addresses.
  Future<void> load() async {
    final at = DateTime.tryParse(_draft.scheduledAt ?? '');
    emit(
      SetupState(timing: at == null ? Timing.asap : Timing.scheduled, at: at),
    );
    try {
      final options = await _repo.options(_draft.serviceId, _draft.providerId!);
      emit(
        state.copyWith(
          view: ViewData(options),
          timing: _fixed(options) ? Timing.scheduled : state.timing,
          addressId: _default(options.addresses),
        ),
      );
    } on Object catch (e) {
      emit(state.copyWith(view: ViewFailure(AppFailure.from(e))));
    }
  }

  String? _default(List<Address> list) =>
      (list.where((a) => a.isDefault ?? false).firstOrNull ?? list.firstOrNull)
          ?.id;

  // A duration hire is always booked for a start time (D2).
  bool _fixed(BookingOptions o) =>
      o.service.serviceModel == ServiceModel.durationHire;

  /// Reloads the addresses after one was added, keeping the choice.
  Future<void> reloadAddresses() async {
    final options = state.options!;
    final failure = await attempt(() async {
      final list = await _repo.addresses();
      final keep = list.any((a) => a.id == state.addressId);
      final view = ViewData(
        BookingOptions(
          service: options.service,
          provider: options.provider,
          addresses: list,
        ),
      );
      emit(
        state.copyWith(
          view: view,
          addressId: keep ? state.addressId : _default(list),
        ),
      );
    });
    if (failure != null) emit(state.copyWith(failure: failure));
  }

  /// Chooses ASAP or a scheduled slot.
  void timing(Timing timing) => emit(state.copyWith(timing: timing));

  /// Sets the scheduled start, flagging one that cannot be booked.
  void schedule(DateTime at) =>
      emit(state.copyWith(at: at, invalidTime: !schedulable(at, _now())));

  /// Chooses the service address.
  void address(String id) => emit(state.copyWith(addressId: id));

  /// The chosen items priced from the catalog.
  List<BillLine> get lines => draftLines(state.options!.service, _draft.items);

  /// Whether a scheduled start is missing or too soon or too far.
  bool get _badTime {
    final at = state.at;
    return state.timing == Timing.scheduled &&
        (at == null || !schedulable(at, _now()));
  }

  /// Requests the booking with [note].
  Future<void> confirm(String note) async {
    if (_badTime) return emit(state.copyWith(invalidTime: true));
    final request = _request(note.trim());
    final body = jsonEncode(request.toJson());
    if (_attempt?.$1 != body) _attempt = (body, _newKey());
    emit(state.copyWith(busy: true));
    try {
      final booking = await _repo.create(request, key: _attempt!.$2);
      _attempt = null;
      emit(state.copyWith(booking: booking));
    } on Object catch (e) {
      emit(state.copyWith(failure: AppFailure.from(e)));
    }
  }

  BookingCreate _request(String note) {
    final scheduled = state.timing == Timing.scheduled;
    return BookingCreate(
      providerId: _draft.providerId!,
      serviceId: _draft.serviceId,
      items: [
        for (final line in lines)
          BookingItemInput(subServiceId: line.id, quantity: line.quantity),
      ],
      timing: state.timing,
      scheduledAt: scheduled ? state.at!.toUtc() : null,
      addressId: state.addressId!,
      note: note.isEmpty ? null : note,
    );
  }
}
