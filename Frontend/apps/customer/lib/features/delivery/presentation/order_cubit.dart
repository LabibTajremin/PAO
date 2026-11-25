import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';
import 'package:pao_customer/features/booking/domain/schedule.dart';
import 'package:pao_customer/features/delivery/domain/delivery_repository.dart';
import 'package:pao_customer/features/delivery/presentation/order_state.dart';
import 'package:pao_customer/shared/booking_draft.dart';

export 'package:pao_customer/features/delivery/presentation/order_state.dart';

/// The Sunday-to-Thursday office week of Dhaka.
const officeWeek = {0, 1, 2, 3, 4};

/// Orders a scheduled delivery (ADR-0041): the form's choices, then the order.
class OrderCubit extends Cubit<OrderState> {
  /// Creates the cubit for [_draft]; `now` is the app clock and `newKey`
  /// makes idempotency keys.
  OrderCubit(
    this._options,
    this._orders,
    this._draft, {
    required this._now,
    String Function()? newKey,
  }) : _newKey = newKey ?? newIdempotencyKey,
       super(const OrderState());

  final BookingRepository _options;
  final DeliveryRepository _orders;
  final BookingDraft _draft;
  final DateTime Function() _now;
  final String Function() _newKey;

  // Retrying the same order reuses its key, so a lost answer cannot order
  // twice.
  (String request, String key)? _attempt;

  /// Loads the service, provider and addresses and picks the first choices.
  Future<void> load() async {
    try {
      final o = await _options.options(_draft.serviceId, _draft.providerId!);
      final schedule = o.service.schedule!;
      final pattern = schedule.patterns.first;
      final lead = (schedule.leadHours / 24).ceil().clamp(1, 14);
      final today = _now();
      emit(
        state.copyWith(
          view: ViewData(o),
          pattern: pattern,
          weekdays: _days(pattern),
          start: DateTime(today.year, today.month, today.day + lead),
          dayOfMonth: today.day,
          addressId: _default(o.addresses),
        ),
      );
    } on Object catch (e) {
      emit(state.copyWith(view: ViewFailure(AppFailure.from(e))));
    }
  }

  String? _default(List<Address> list) =>
      (list.where((a) => a.isDefault ?? false).firstOrNull ?? list.firstOrNull)
          ?.id;

  Set<int> _days(DeliveryPattern p) => switch (p) {
    DeliveryPattern.weekdays => officeWeek,
    // DateTime counts Monday as 1 and Sunday as 7; the API counts Sunday as 0.
    DeliveryPattern.weekly => {(state.start?.weekday ?? 7) % 7},
    _ => const {},
  };

  /// Chooses how the dates repeat.
  void pattern(DeliveryPattern p) =>
      emit(state.copyWith(pattern: p, weekdays: _days(p)));

  /// Adds or removes a day; a weekly order keeps exactly one.
  void day(int d) {
    final had = state.weekdays.contains(d);
    final days = switch (state.pattern) {
      DeliveryPattern.weekly => {d},
      _ when had => state.weekdays.difference({d}),
      _ => {...state.weekdays, d},
    };
    emit(state.copyWith(weekdays: days));
  }

  /// Chooses the window.
  void window(int i) => emit(state.copyWith(window: i));

  /// Sets the first date.
  void start(DateTime d) => emit(state.copyWith(start: d));

  /// Sets how many deliveries, between 1 and 60.
  void count(int n) => emit(state.copyWith(count: n.clamp(1, 60)));

  /// Sets the day of the month.
  void dayOfMonth(int d) => emit(state.copyWith(dayOfMonth: d));

  /// Chooses the address.
  void address(String id) => emit(state.copyWith(addressId: id));

  /// Sends the order with [note].
  Future<void> confirm(String note) async {
    final request = _request(note.trim());
    final body = jsonEncode(request.toJson());
    if (_attempt?.$1 != body) _attempt = (body, _newKey());
    emit(state.copyWith(busy: true));
    try {
      final created = await _orders.create(request, key: _attempt!.$2);
      _attempt = null;
      emit(state.copyWith(subscription: created));
    } on Object catch (e) {
      emit(state.copyWith(failure: AppFailure.from(e)));
    }
  }

  SubscriptionCreate _request(String note) {
    final s = state;
    final start = s.start!;
    return SubscriptionCreate(
      providerId: _draft.providerId!,
      serviceId: _draft.serviceId,
      items: [
        for (final e in _draft.items.entries)
          BookingItemInput(subServiceId: e.key, quantity: e.value),
      ],
      addressId: s.addressId!,
      pattern: s.pattern,
      weekdays: s.weekdays.isEmpty
          ? null
          : (s.weekdays.toList()..sort()).toSet(),
      dayOfMonth: s.pattern == DeliveryPattern.monthly ? s.dayOfMonth : null,
      window: s.schedule!.windows[s.window],
      startDate: isoDate(start),
      count: s.repeats ? s.count : null,
      note: note.isEmpty ? null : note,
    );
  }
}

/// A date as the API writes it, `yyyy-mm-dd`.
String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
