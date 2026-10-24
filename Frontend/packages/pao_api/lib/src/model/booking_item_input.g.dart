// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_item_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingItemInputCWProxy {
  BookingItemInput subServiceId(String subServiceId);

  BookingItemInput quantity(int quantity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingItemInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingItemInput(...).copyWith(id: 12, name: "My name")
  /// ```
  BookingItemInput call({String subServiceId, int quantity});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBookingItemInput.copyWith(...)` or call `instanceOfBookingItemInput.copyWith.fieldName(value)` for a single field.
class _$BookingItemInputCWProxyImpl implements _$BookingItemInputCWProxy {
  const _$BookingItemInputCWProxyImpl(this._value);

  final BookingItemInput _value;

  @override
  BookingItemInput subServiceId(String subServiceId) =>
      call(subServiceId: subServiceId);

  @override
  BookingItemInput quantity(int quantity) => call(quantity: quantity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingItemInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingItemInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BookingItemInput call({
    Object? subServiceId = const $CopyWithPlaceholder(),
    Object? quantity = const $CopyWithPlaceholder(),
  }) {
    return BookingItemInput(
      subServiceId:
          subServiceId == const $CopyWithPlaceholder() || subServiceId == null
          ? _value.subServiceId
          // ignore: cast_nullable_to_non_nullable
          : subServiceId as String,
      quantity: quantity == const $CopyWithPlaceholder() || quantity == null
          ? _value.quantity
          // ignore: cast_nullable_to_non_nullable
          : quantity as int,
    );
  }
}

extension $BookingItemInputCopyWith on BookingItemInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBookingItemInput.copyWith(...)` or `instanceOfBookingItemInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingItemInputCWProxy get copyWith => _$BookingItemInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingItemInput _$BookingItemInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BookingItemInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['subServiceId', 'quantity']);
      final val = BookingItemInput(
        subServiceId: $checkedConvert('subServiceId', (v) => v as String),
        quantity: $checkedConvert('quantity', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$BookingItemInputToJson(BookingItemInput instance) =>
    <String, dynamic>{
      'subServiceId': instance.subServiceId,
      'quantity': instance.quantity,
    };
