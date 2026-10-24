// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_reject_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentRejectInputCWProxy {
  PaymentRejectInput reason(String reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentRejectInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentRejectInput(...).copyWith(id: 12, name: "My name")
  /// ```
  PaymentRejectInput call({String reason});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaymentRejectInput.copyWith(...)` or call `instanceOfPaymentRejectInput.copyWith.fieldName(value)` for a single field.
class _$PaymentRejectInputCWProxyImpl implements _$PaymentRejectInputCWProxy {
  const _$PaymentRejectInputCWProxyImpl(this._value);

  final PaymentRejectInput _value;

  @override
  PaymentRejectInput reason(String reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentRejectInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentRejectInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaymentRejectInput call({Object? reason = const $CopyWithPlaceholder()}) {
    return PaymentRejectInput(
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $PaymentRejectInputCopyWith on PaymentRejectInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaymentRejectInput.copyWith(...)` or `instanceOfPaymentRejectInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentRejectInputCWProxy get copyWith =>
      _$PaymentRejectInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRejectInput _$PaymentRejectInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PaymentRejectInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = PaymentRejectInput(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PaymentRejectInputToJson(PaymentRejectInput instance) =>
    <String, dynamic>{'reason': instance.reason};
