// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubscriptionCWProxy {
  Subscription id(String id);

  Subscription number(String number);

  Subscription status(SubscriptionStatus status);

  Subscription serviceId(String serviceId);

  Subscription serviceName(LocalizedText serviceName);

  Subscription provider(BookingParty? provider);

  Subscription customer(BookingParty? customer);

  Subscription items(List<BookingItem> items);

  Subscription total(int total);

  Subscription unit(QuantityUnit? unit);

  Subscription pattern(DeliveryPattern pattern);

  Subscription weekdays(List<int>? weekdays);

  Subscription dayOfMonth(int? dayOfMonth);

  Subscription window(DeliveryWindow window);

  Subscription startDate(String startDate);

  Subscription endDate(String? endDate);

  Subscription count(int? count);

  Subscription address(BookingAddress address);

  Subscription note(String? note);

  Subscription createdAt(DateTime createdAt);

  Subscription upcoming(List<DeliveryDate>? upcoming);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Subscription(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Subscription(...).copyWith(id: 12, name: "My name")
  /// ```
  Subscription call({
    String id,
    String number,
    SubscriptionStatus status,
    String serviceId,
    LocalizedText serviceName,
    BookingParty? provider,
    BookingParty? customer,
    List<BookingItem> items,
    int total,
    QuantityUnit? unit,
    DeliveryPattern pattern,
    List<int>? weekdays,
    int? dayOfMonth,
    DeliveryWindow window,
    String startDate,
    String? endDate,
    int? count,
    BookingAddress address,
    String? note,
    DateTime createdAt,
    List<DeliveryDate>? upcoming,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubscription.copyWith(...)` or call `instanceOfSubscription.copyWith.fieldName(value)` for a single field.
class _$SubscriptionCWProxyImpl implements _$SubscriptionCWProxy {
  const _$SubscriptionCWProxyImpl(this._value);

  final Subscription _value;

  @override
  Subscription id(String id) => call(id: id);

  @override
  Subscription number(String number) => call(number: number);

  @override
  Subscription status(SubscriptionStatus status) => call(status: status);

  @override
  Subscription serviceId(String serviceId) => call(serviceId: serviceId);

  @override
  Subscription serviceName(LocalizedText serviceName) =>
      call(serviceName: serviceName);

  @override
  Subscription provider(BookingParty? provider) => call(provider: provider);

  @override
  Subscription customer(BookingParty? customer) => call(customer: customer);

  @override
  Subscription items(List<BookingItem> items) => call(items: items);

  @override
  Subscription total(int total) => call(total: total);

  @override
  Subscription unit(QuantityUnit? unit) => call(unit: unit);

  @override
  Subscription pattern(DeliveryPattern pattern) => call(pattern: pattern);

  @override
  Subscription weekdays(List<int>? weekdays) => call(weekdays: weekdays);

  @override
  Subscription dayOfMonth(int? dayOfMonth) => call(dayOfMonth: dayOfMonth);

  @override
  Subscription window(DeliveryWindow window) => call(window: window);

  @override
  Subscription startDate(String startDate) => call(startDate: startDate);

  @override
  Subscription endDate(String? endDate) => call(endDate: endDate);

  @override
  Subscription count(int? count) => call(count: count);

  @override
  Subscription address(BookingAddress address) => call(address: address);

  @override
  Subscription note(String? note) => call(note: note);

  @override
  Subscription createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  Subscription upcoming(List<DeliveryDate>? upcoming) =>
      call(upcoming: upcoming);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Subscription(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Subscription(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Subscription call({
    Object? id = const $CopyWithPlaceholder(),
    Object? number = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? serviceName = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? customer = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? pattern = const $CopyWithPlaceholder(),
    Object? weekdays = const $CopyWithPlaceholder(),
    Object? dayOfMonth = const $CopyWithPlaceholder(),
    Object? window = const $CopyWithPlaceholder(),
    Object? startDate = const $CopyWithPlaceholder(),
    Object? endDate = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? upcoming = const $CopyWithPlaceholder(),
  }) {
    return Subscription(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      number: number == const $CopyWithPlaceholder() || number == null
          ? _value.number
          // ignore: cast_nullable_to_non_nullable
          : number as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as SubscriptionStatus,
      serviceId: serviceId == const $CopyWithPlaceholder() || serviceId == null
          ? _value.serviceId
          // ignore: cast_nullable_to_non_nullable
          : serviceId as String,
      serviceName:
          serviceName == const $CopyWithPlaceholder() || serviceName == null
          ? _value.serviceName
          // ignore: cast_nullable_to_non_nullable
          : serviceName as LocalizedText,
      provider: provider == const $CopyWithPlaceholder()
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as BookingParty?,
      customer: customer == const $CopyWithPlaceholder()
          ? _value.customer
          // ignore: cast_nullable_to_non_nullable
          : customer as BookingParty?,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItem>,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as QuantityUnit?,
      pattern: pattern == const $CopyWithPlaceholder() || pattern == null
          ? _value.pattern
          // ignore: cast_nullable_to_non_nullable
          : pattern as DeliveryPattern,
      weekdays: weekdays == const $CopyWithPlaceholder()
          ? _value.weekdays
          // ignore: cast_nullable_to_non_nullable
          : weekdays as List<int>?,
      dayOfMonth: dayOfMonth == const $CopyWithPlaceholder()
          ? _value.dayOfMonth
          // ignore: cast_nullable_to_non_nullable
          : dayOfMonth as int?,
      window: window == const $CopyWithPlaceholder() || window == null
          ? _value.window
          // ignore: cast_nullable_to_non_nullable
          : window as DeliveryWindow,
      startDate: startDate == const $CopyWithPlaceholder() || startDate == null
          ? _value.startDate
          // ignore: cast_nullable_to_non_nullable
          : startDate as String,
      endDate: endDate == const $CopyWithPlaceholder()
          ? _value.endDate
          // ignore: cast_nullable_to_non_nullable
          : endDate as String?,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int?,
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as BookingAddress,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      upcoming: upcoming == const $CopyWithPlaceholder()
          ? _value.upcoming
          // ignore: cast_nullable_to_non_nullable
          : upcoming as List<DeliveryDate>?,
    );
  }
}

extension $SubscriptionCopyWith on Subscription {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubscription.copyWith(...)` or `instanceOfSubscription.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubscriptionCWProxy get copyWith => _$SubscriptionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Subscription', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'number',
      'status',
      'serviceId',
      'serviceName',
      'items',
      'total',
      'pattern',
      'window',
      'startDate',
      'address',
      'createdAt',
    ],
  );
  final val = Subscription(
    id: $checkedConvert('id', (v) => v as String),
    number: $checkedConvert('number', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$SubscriptionStatusEnumMap, v),
    ),
    serviceId: $checkedConvert('serviceId', (v) => v as String),
    serviceName: $checkedConvert(
      'serviceName',
      (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
    ),
    provider: $checkedConvert(
      'provider',
      (v) =>
          v == null ? null : BookingParty.fromJson(v as Map<String, dynamic>),
    ),
    customer: $checkedConvert(
      'customer',
      (v) =>
          v == null ? null : BookingParty.fromJson(v as Map<String, dynamic>),
    ),
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => BookingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    total: $checkedConvert('total', (v) => (v as num).toInt()),
    unit: $checkedConvert(
      'unit',
      (v) => $enumDecodeNullable(_$QuantityUnitEnumMap, v),
    ),
    pattern: $checkedConvert(
      'pattern',
      (v) => $enumDecode(_$DeliveryPatternEnumMap, v),
    ),
    weekdays: $checkedConvert(
      'weekdays',
      (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
    ),
    dayOfMonth: $checkedConvert('dayOfMonth', (v) => (v as num?)?.toInt()),
    window: $checkedConvert(
      'window',
      (v) => DeliveryWindow.fromJson(v as Map<String, dynamic>),
    ),
    startDate: $checkedConvert('startDate', (v) => v as String),
    endDate: $checkedConvert('endDate', (v) => v as String?),
    count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
    address: $checkedConvert(
      'address',
      (v) => BookingAddress.fromJson(v as Map<String, dynamic>),
    ),
    note: $checkedConvert('note', (v) => v as String?),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    upcoming: $checkedConvert(
      'upcoming',
      (v) => (v as List<dynamic>?)
          ?.map((e) => DeliveryDate.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'status': _$SubscriptionStatusEnumMap[instance.status]!,
      'serviceId': instance.serviceId,
      'serviceName': instance.serviceName.toJson(),
      'provider': ?instance.provider?.toJson(),
      'customer': ?instance.customer?.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'unit': ?_$QuantityUnitEnumMap[instance.unit],
      'pattern': _$DeliveryPatternEnumMap[instance.pattern]!,
      'weekdays': ?instance.weekdays,
      'dayOfMonth': ?instance.dayOfMonth,
      'window': instance.window.toJson(),
      'startDate': instance.startDate,
      'endDate': ?instance.endDate,
      'count': ?instance.count,
      'address': instance.address.toJson(),
      'note': ?instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'upcoming': ?instance.upcoming?.map((e) => e.toJson()).toList(),
    };

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.requested: 'requested',
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.paused: 'paused',
  SubscriptionStatus.finished: 'finished',
  SubscriptionStatus.declined: 'declined',
  SubscriptionStatus.cancelled: 'cancelled',
};

const _$QuantityUnitEnumMap = {
  QuantityUnit.meals: 'meals',
  QuantityUnit.guests: 'guests',
  QuantityUnit.package: 'package',
};

const _$DeliveryPatternEnumMap = {
  DeliveryPattern.once: 'once',
  DeliveryPattern.daily: 'daily',
  DeliveryPattern.weekdays: 'weekdays',
  DeliveryPattern.weekly: 'weekly',
  DeliveryPattern.monthly: 'monthly',
};
