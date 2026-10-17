// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PriceInputCWProxy {
  PriceInput amount(int amount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceInput(...).copyWith(id: 12, name: "My name")
  /// ```
  PriceInput call({int amount});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPriceInput.copyWith(...)` or call `instanceOfPriceInput.copyWith.fieldName(value)` for a single field.
class _$PriceInputCWProxyImpl implements _$PriceInputCWProxy {
  const _$PriceInputCWProxyImpl(this._value);

  final PriceInput _value;

  @override
  PriceInput amount(int amount) => call(amount: amount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PriceInput call({Object? amount = const $CopyWithPlaceholder()}) {
    return PriceInput(
      amount: amount == const $CopyWithPlaceholder() || amount == null
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
    );
  }
}

extension $PriceInputCopyWith on PriceInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPriceInput.copyWith(...)` or `instanceOfPriceInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PriceInputCWProxy get copyWith => _$PriceInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceInput _$PriceInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PriceInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['amount']);
      final val = PriceInput(
        amount: $checkedConvert('amount', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$PriceInputToJson(PriceInput instance) =>
    <String, dynamic>{'amount': instance.amount};
