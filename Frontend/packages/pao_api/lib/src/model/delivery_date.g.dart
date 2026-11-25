// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_date.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeliveryDateCWProxy {
  DeliveryDate date(String date);

  DeliveryDate status(DeliveryStatus status);

  DeliveryDate items(List<BookingItemInput> items);

  DeliveryDate total(int total);

  DeliveryDate bookingId(String? bookingId);

  DeliveryDate changeable(bool? changeable);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeliveryDate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeliveryDate(...).copyWith(id: 12, name: "My name")
  /// ```
  DeliveryDate call({
    String date,
    DeliveryStatus status,
    List<BookingItemInput> items,
    int total,
    String? bookingId,
    bool? changeable,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeliveryDate.copyWith(...)` or call `instanceOfDeliveryDate.copyWith.fieldName(value)` for a single field.
class _$DeliveryDateCWProxyImpl implements _$DeliveryDateCWProxy {
  const _$DeliveryDateCWProxyImpl(this._value);

  final DeliveryDate _value;

  @override
  DeliveryDate date(String date) => call(date: date);

  @override
  DeliveryDate status(DeliveryStatus status) => call(status: status);

  @override
  DeliveryDate items(List<BookingItemInput> items) => call(items: items);

  @override
  DeliveryDate total(int total) => call(total: total);

  @override
  DeliveryDate bookingId(String? bookingId) => call(bookingId: bookingId);

  @override
  DeliveryDate changeable(bool? changeable) => call(changeable: changeable);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeliveryDate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeliveryDate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeliveryDate call({
    Object? date = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? bookingId = const $CopyWithPlaceholder(),
    Object? changeable = const $CopyWithPlaceholder(),
  }) {
    return DeliveryDate(
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as DeliveryStatus,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItemInput>,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      bookingId: bookingId == const $CopyWithPlaceholder()
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String?,
      changeable: changeable == const $CopyWithPlaceholder()
          ? _value.changeable
          // ignore: cast_nullable_to_non_nullable
          : changeable as bool?,
    );
  }
}

extension $DeliveryDateCopyWith on DeliveryDate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeliveryDate.copyWith(...)` or `instanceOfDeliveryDate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeliveryDateCWProxy get copyWith => _$DeliveryDateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryDate _$DeliveryDateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeliveryDate', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['date', 'status', 'items', 'total'],
      );
      final val = DeliveryDate(
        date: $checkedConvert('date', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$DeliveryStatusEnumMap, v),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BookingItemInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        bookingId: $checkedConvert('bookingId', (v) => v as String?),
        changeable: $checkedConvert('changeable', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$DeliveryDateToJson(DeliveryDate instance) =>
    <String, dynamic>{
      'date': instance.date,
      'status': _$DeliveryStatusEnumMap[instance.status]!,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'bookingId': ?instance.bookingId,
      'changeable': ?instance.changeable,
    };

const _$DeliveryStatusEnumMap = {
  DeliveryStatus.scheduled: 'scheduled',
  DeliveryStatus.preparing: 'preparing',
  DeliveryStatus.outForDelivery: 'out_for_delivery',
  DeliveryStatus.delivered: 'delivered',
  DeliveryStatus.skipped: 'skipped',
  DeliveryStatus.declined: 'declined',
  DeliveryStatus.cancelled: 'cancelled',
};
