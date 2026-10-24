// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingItemCWProxy {
  BookingItem subServiceId(String subServiceId);

  BookingItem priceVersionId(String priceVersionId);

  BookingItem name(LocalizedText name);

  BookingItem unit(PriceUnit unit);

  BookingItem quantity(int quantity);

  BookingItem unitPrice(int unitPrice);

  BookingItem total(int total);

  BookingItem extra(bool extra);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingItem(...).copyWith(id: 12, name: "My name")
  /// ```
  BookingItem call({
    String subServiceId,
    String priceVersionId,
    LocalizedText name,
    PriceUnit unit,
    int quantity,
    int unitPrice,
    int total,
    bool extra,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBookingItem.copyWith(...)` or call `instanceOfBookingItem.copyWith.fieldName(value)` for a single field.
class _$BookingItemCWProxyImpl implements _$BookingItemCWProxy {
  const _$BookingItemCWProxyImpl(this._value);

  final BookingItem _value;

  @override
  BookingItem subServiceId(String subServiceId) =>
      call(subServiceId: subServiceId);

  @override
  BookingItem priceVersionId(String priceVersionId) =>
      call(priceVersionId: priceVersionId);

  @override
  BookingItem name(LocalizedText name) => call(name: name);

  @override
  BookingItem unit(PriceUnit unit) => call(unit: unit);

  @override
  BookingItem quantity(int quantity) => call(quantity: quantity);

  @override
  BookingItem unitPrice(int unitPrice) => call(unitPrice: unitPrice);

  @override
  BookingItem total(int total) => call(total: total);

  @override
  BookingItem extra(bool extra) => call(extra: extra);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BookingItem call({
    Object? subServiceId = const $CopyWithPlaceholder(),
    Object? priceVersionId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? quantity = const $CopyWithPlaceholder(),
    Object? unitPrice = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? extra = const $CopyWithPlaceholder(),
  }) {
    return BookingItem(
      subServiceId:
          subServiceId == const $CopyWithPlaceholder() || subServiceId == null
          ? _value.subServiceId
          // ignore: cast_nullable_to_non_nullable
          : subServiceId as String,
      priceVersionId:
          priceVersionId == const $CopyWithPlaceholder() ||
              priceVersionId == null
          ? _value.priceVersionId
          // ignore: cast_nullable_to_non_nullable
          : priceVersionId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as LocalizedText,
      unit: unit == const $CopyWithPlaceholder() || unit == null
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as PriceUnit,
      quantity: quantity == const $CopyWithPlaceholder() || quantity == null
          ? _value.quantity
          // ignore: cast_nullable_to_non_nullable
          : quantity as int,
      unitPrice: unitPrice == const $CopyWithPlaceholder() || unitPrice == null
          ? _value.unitPrice
          // ignore: cast_nullable_to_non_nullable
          : unitPrice as int,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      extra: extra == const $CopyWithPlaceholder() || extra == null
          ? _value.extra
          // ignore: cast_nullable_to_non_nullable
          : extra as bool,
    );
  }
}

extension $BookingItemCopyWith on BookingItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBookingItem.copyWith(...)` or `instanceOfBookingItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingItemCWProxy get copyWith => _$BookingItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingItem _$BookingItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BookingItem',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'subServiceId',
        'priceVersionId',
        'name',
        'unit',
        'quantity',
        'unitPrice',
        'total',
        'extra',
      ],
    );
    final val = BookingItem(
      subServiceId: $checkedConvert('subServiceId', (v) => v as String),
      priceVersionId: $checkedConvert('priceVersionId', (v) => v as String),
      name: $checkedConvert(
        'name',
        (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
      ),
      unit: $checkedConvert('unit', (v) => $enumDecode(_$PriceUnitEnumMap, v)),
      quantity: $checkedConvert('quantity', (v) => (v as num).toInt()),
      unitPrice: $checkedConvert('unitPrice', (v) => (v as num).toInt()),
      total: $checkedConvert('total', (v) => (v as num).toInt()),
      extra: $checkedConvert('extra', (v) => v as bool),
    );
    return val;
  },
);

Map<String, dynamic> _$BookingItemToJson(BookingItem instance) =>
    <String, dynamic>{
      'subServiceId': instance.subServiceId,
      'priceVersionId': instance.priceVersionId,
      'name': instance.name.toJson(),
      'unit': _$PriceUnitEnumMap[instance.unit]!,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'total': instance.total,
      'extra': instance.extra,
    };

const _$PriceUnitEnumMap = {
  PriceUnit.job: 'job',
  PriceUnit.unit: 'unit',
  PriceUnit.hour: 'hour',
  PriceUnit.day: 'day',
};
