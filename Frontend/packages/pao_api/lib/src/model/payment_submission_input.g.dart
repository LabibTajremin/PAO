// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_submission_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentSubmissionInputCWProxy {
  PaymentSubmissionInput amountPaisa(int amountPaisa);

  PaymentSubmissionInput method(PaymentMethodKind method);

  PaymentSubmissionInput reference(String reference);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentSubmissionInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentSubmissionInput(...).copyWith(id: 12, name: "My name")
  /// ```
  PaymentSubmissionInput call({
    int amountPaisa,
    PaymentMethodKind method,
    String reference,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaymentSubmissionInput.copyWith(...)` or call `instanceOfPaymentSubmissionInput.copyWith.fieldName(value)` for a single field.
class _$PaymentSubmissionInputCWProxyImpl
    implements _$PaymentSubmissionInputCWProxy {
  const _$PaymentSubmissionInputCWProxyImpl(this._value);

  final PaymentSubmissionInput _value;

  @override
  PaymentSubmissionInput amountPaisa(int amountPaisa) =>
      call(amountPaisa: amountPaisa);

  @override
  PaymentSubmissionInput method(PaymentMethodKind method) =>
      call(method: method);

  @override
  PaymentSubmissionInput reference(String reference) =>
      call(reference: reference);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentSubmissionInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentSubmissionInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaymentSubmissionInput call({
    Object? amountPaisa = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
  }) {
    return PaymentSubmissionInput(
      amountPaisa:
          amountPaisa == const $CopyWithPlaceholder() || amountPaisa == null
          ? _value.amountPaisa
          // ignore: cast_nullable_to_non_nullable
          : amountPaisa as int,
      method: method == const $CopyWithPlaceholder() || method == null
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as PaymentMethodKind,
      reference: reference == const $CopyWithPlaceholder() || reference == null
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
    );
  }
}

extension $PaymentSubmissionInputCopyWith on PaymentSubmissionInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaymentSubmissionInput.copyWith(...)` or `instanceOfPaymentSubmissionInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentSubmissionInputCWProxy get copyWith =>
      _$PaymentSubmissionInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentSubmissionInput _$PaymentSubmissionInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PaymentSubmissionInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['amountPaisa', 'method', 'reference']);
  final val = PaymentSubmissionInput(
    amountPaisa: $checkedConvert('amountPaisa', (v) => (v as num).toInt()),
    method: $checkedConvert(
      'method',
      (v) => $enumDecode(_$PaymentMethodKindEnumMap, v),
    ),
    reference: $checkedConvert('reference', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$PaymentSubmissionInputToJson(
  PaymentSubmissionInput instance,
) => <String, dynamic>{
  'amountPaisa': instance.amountPaisa,
  'method': _$PaymentMethodKindEnumMap[instance.method]!,
  'reference': instance.reference,
};

const _$PaymentMethodKindEnumMap = {
  PaymentMethodKind.cashToAgent: 'cash_to_agent',
  PaymentMethodKind.bkash: 'bkash',
  PaymentMethodKind.nagad: 'nagad',
  PaymentMethodKind.bank: 'bank',
};
