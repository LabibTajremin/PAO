import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';

/// The scheduled-delivery order form (P25): how the dates repeat, the window,
/// the first date, how many deliveries and the address.
class OrderState {
  /// Creates the state.
  const OrderState({
    this.view = const ViewLoading(),
    this.pattern = DeliveryPattern.once,
    this.weekdays = const {},
    this.dayOfMonth = 1,
    this.window = 0,
    this.start,
    this.count = 10,
    this.addressId,
    this.busy = false,
    this.failure,
    this.subscription,
  });

  /// The service, provider and addresses.
  final ViewState<BookingOptions> view;

  /// How the dates repeat.
  final DeliveryPattern pattern;

  /// The chosen days, 0 Sunday to 6 Saturday.
  final Set<int> weekdays;

  /// The day of the month for a monthly order.
  final int dayOfMonth;

  /// The chosen window's index in the service's schedule.
  final int window;

  /// The first date.
  final DateTime? start;

  /// How many deliveries; one for a one-time order.
  final int count;

  /// The chosen address.
  final String? addressId;

  /// The order is being sent.
  final bool busy;

  /// Why the last order failed.
  final AppFailure? failure;

  /// The created order; the page moves on.
  final Subscription? subscription;

  /// The loaded options, if any.
  BookingOptions? get options => switch (view) {
    ViewData(:final data) => data,
    _ => null,
  };

  /// The service's ordering rules, once loaded.
  ServiceSchedule? get schedule => options?.service.schedule;

  /// Whether the pattern repeats and so needs a count.
  bool get repeats => pattern != DeliveryPattern.once;

  /// A copy with changes; [busy] and [failure] start afresh with each action.
  OrderState copyWith({
    ViewState<BookingOptions>? view,
    DeliveryPattern? pattern,
    Set<int>? weekdays,
    int? dayOfMonth,
    int? window,
    DateTime? start,
    int? count,
    String? addressId,
    bool busy = false,
    AppFailure? failure,
    Subscription? subscription,
  }) => OrderState(
    view: view ?? this.view,
    pattern: pattern ?? this.pattern,
    weekdays: weekdays ?? this.weekdays,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    window: window ?? this.window,
    start: start ?? this.start,
    count: count ?? this.count,
    addressId: addressId ?? this.addressId,
    busy: busy,
    failure: failure,
    subscription: subscription ?? this.subscription,
  );
}
