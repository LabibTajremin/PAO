// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_change.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeliveryChangeCWProxy {
  DeliveryChange skip(bool? skip);

  DeliveryChange items(List<BookingItemInput>? items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeliveryChange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeliveryChange(...).copyWith(id: 12, name: "My name")
  /// ```
  DeliveryChange call({bool? skip, List<BookingItemInput>? items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeliveryChange.copyWith(...)` or call `instanceOfDeliveryChange.copyWith.fieldName(value)` for a single field.
class _$DeliveryChangeCWProxyImpl implements _$DeliveryChangeCWProxy {
  const _$DeliveryChangeCWProxyImpl(this._value);

  final DeliveryChange _value;

  @override
  DeliveryChange skip(bool? skip) => call(skip: skip);

  @override
  DeliveryChange items(List<BookingItemInput>? items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeliveryChange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeliveryChange(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeliveryChange call({
    Object? skip = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return DeliveryChange(
      skip: skip == const $CopyWithPlaceholder()
          ? _value.skip
          // ignore: cast_nullable_to_non_nullable
          : skip as bool?,
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItemInput>?,
    );
  }
}

extension $DeliveryChangeCopyWith on DeliveryChange {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeliveryChange.copyWith(...)` or `instanceOfDeliveryChange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeliveryChangeCWProxy get copyWith => _$DeliveryChangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryChange _$DeliveryChangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeliveryChange', json, ($checkedConvert) {
      final val = DeliveryChange(
        skip: $checkedConvert('skip', (v) => v as bool?),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>?)
              ?.map((e) => BookingItemInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DeliveryChangeToJson(DeliveryChange instance) =>
    <String, dynamic>{
      'skip': ?instance.skip,
      'items': ?instance.items?.map((e) => e.toJson()).toList(),
    };
