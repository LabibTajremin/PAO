// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubscriptionCreateCWProxy {
  SubscriptionCreate providerId(String providerId);

  SubscriptionCreate serviceId(String serviceId);

  SubscriptionCreate items(List<BookingItemInput> items);

  SubscriptionCreate addressId(String addressId);

  SubscriptionCreate pattern(DeliveryPattern pattern);

  SubscriptionCreate weekdays(Set<int>? weekdays);

  SubscriptionCreate dayOfMonth(int? dayOfMonth);

  SubscriptionCreate window(DeliveryWindow window);

  SubscriptionCreate startDate(String startDate);

  SubscriptionCreate endDate(String? endDate);

  SubscriptionCreate count(int? count);

  SubscriptionCreate note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubscriptionCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubscriptionCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  SubscriptionCreate call({
    String providerId,
    String serviceId,
    List<BookingItemInput> items,
    String addressId,
    DeliveryPattern pattern,
    Set<int>? weekdays,
    int? dayOfMonth,
    DeliveryWindow window,
    String startDate,
    String? endDate,
    int? count,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubscriptionCreate.copyWith(...)` or call `instanceOfSubscriptionCreate.copyWith.fieldName(value)` for a single field.
class _$SubscriptionCreateCWProxyImpl implements _$SubscriptionCreateCWProxy {
  const _$SubscriptionCreateCWProxyImpl(this._value);

  final SubscriptionCreate _value;

  @override
  SubscriptionCreate providerId(String providerId) =>
      call(providerId: providerId);

  @override
  SubscriptionCreate serviceId(String serviceId) => call(serviceId: serviceId);

  @override
  SubscriptionCreate items(List<BookingItemInput> items) => call(items: items);

  @override
  SubscriptionCreate addressId(String addressId) => call(addressId: addressId);

  @override
  SubscriptionCreate pattern(DeliveryPattern pattern) => call(pattern: pattern);

  @override
  SubscriptionCreate weekdays(Set<int>? weekdays) => call(weekdays: weekdays);

  @override
  SubscriptionCreate dayOfMonth(int? dayOfMonth) =>
      call(dayOfMonth: dayOfMonth);

  @override
  SubscriptionCreate window(DeliveryWindow window) => call(window: window);

  @override
  SubscriptionCreate startDate(String startDate) => call(startDate: startDate);

  @override
  SubscriptionCreate endDate(String? endDate) => call(endDate: endDate);

  @override
  SubscriptionCreate count(int? count) => call(count: count);

  @override
  SubscriptionCreate note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubscriptionCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubscriptionCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SubscriptionCreate call({
    Object? providerId = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? addressId = const $CopyWithPlaceholder(),
    Object? pattern = const $CopyWithPlaceholder(),
    Object? weekdays = const $CopyWithPlaceholder(),
    Object? dayOfMonth = const $CopyWithPlaceholder(),
    Object? window = const $CopyWithPlaceholder(),
    Object? startDate = const $CopyWithPlaceholder(),
    Object? endDate = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return SubscriptionCreate(
      providerId:
          providerId == const $CopyWithPlaceholder() || providerId == null
          ? _value.providerId
          // ignore: cast_nullable_to_non_nullable
          : providerId as String,
      serviceId: serviceId == const $CopyWithPlaceholder() || serviceId == null
          ? _value.serviceId
          // ignore: cast_nullable_to_non_nullable
          : serviceId as String,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItemInput>,
      addressId: addressId == const $CopyWithPlaceholder() || addressId == null
          ? _value.addressId
          // ignore: cast_nullable_to_non_nullable
          : addressId as String,
      pattern: pattern == const $CopyWithPlaceholder() || pattern == null
          ? _value.pattern
          // ignore: cast_nullable_to_non_nullable
          : pattern as DeliveryPattern,
      weekdays: weekdays == const $CopyWithPlaceholder()
          ? _value.weekdays
          // ignore: cast_nullable_to_non_nullable
          : weekdays as Set<int>?,
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
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $SubscriptionCreateCopyWith on SubscriptionCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubscriptionCreate.copyWith(...)` or `instanceOfSubscriptionCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubscriptionCreateCWProxy get copyWith =>
      _$SubscriptionCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionCreate _$SubscriptionCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubscriptionCreate', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'providerId',
          'serviceId',
          'items',
          'addressId',
          'pattern',
          'window',
          'startDate',
        ],
      );
      final val = SubscriptionCreate(
        providerId: $checkedConvert('providerId', (v) => v as String),
        serviceId: $checkedConvert('serviceId', (v) => v as String),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BookingItemInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        addressId: $checkedConvert('addressId', (v) => v as String),
        pattern: $checkedConvert(
          'pattern',
          (v) => $enumDecode(_$DeliveryPatternEnumMap, v),
        ),
        weekdays: $checkedConvert(
          'weekdays',
          (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toSet(),
        ),
        dayOfMonth: $checkedConvert('dayOfMonth', (v) => (v as num?)?.toInt()),
        window: $checkedConvert(
          'window',
          (v) => DeliveryWindow.fromJson(v as Map<String, dynamic>),
        ),
        startDate: $checkedConvert('startDate', (v) => v as String),
        endDate: $checkedConvert('endDate', (v) => v as String?),
        count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SubscriptionCreateToJson(SubscriptionCreate instance) =>
    <String, dynamic>{
      'providerId': instance.providerId,
      'serviceId': instance.serviceId,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'addressId': instance.addressId,
      'pattern': _$DeliveryPatternEnumMap[instance.pattern]!,
      'weekdays': ?instance.weekdays?.toList(),
      'dayOfMonth': ?instance.dayOfMonth,
      'window': instance.window.toJson(),
      'startDate': instance.startDate,
      'endDate': ?instance.endDate,
      'count': ?instance.count,
      'note': ?instance.note,
    };

const _$DeliveryPatternEnumMap = {
  DeliveryPattern.once: 'once',
  DeliveryPattern.daily: 'daily',
  DeliveryPattern.weekdays: 'weekdays',
  DeliveryPattern.weekly: 'weekly',
  DeliveryPattern.monthly: 'monthly',
};
