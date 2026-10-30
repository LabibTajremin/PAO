// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_submission.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentSubmissionCWProxy {
  PaymentSubmission id(String id);

  PaymentSubmission providerId(String providerId);

  PaymentSubmission amount(int amount);

  PaymentSubmission method(PaymentMethodKind method);

  PaymentSubmission reference(String reference);

  PaymentSubmission status(PaymentSubmissionStatus status);

  PaymentSubmission reviewerId(String? reviewerId);

  PaymentSubmission reason(String? reason);

  PaymentSubmission createdAt(DateTime createdAt);

  PaymentSubmission reviewedAt(DateTime? reviewedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentSubmission(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentSubmission(...).copyWith(id: 12, name: "My name")
  /// ```
  PaymentSubmission call({
    String id,
    String providerId,
    int amount,
    PaymentMethodKind method,
    String reference,
    PaymentSubmissionStatus status,
    String? reviewerId,
    String? reason,
    DateTime createdAt,
    DateTime? reviewedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaymentSubmission.copyWith(...)` or call `instanceOfPaymentSubmission.copyWith.fieldName(value)` for a single field.
class _$PaymentSubmissionCWProxyImpl implements _$PaymentSubmissionCWProxy {
  const _$PaymentSubmissionCWProxyImpl(this._value);

  final PaymentSubmission _value;

  @override
  PaymentSubmission id(String id) => call(id: id);

  @override
  PaymentSubmission providerId(String providerId) =>
      call(providerId: providerId);

  @override
  PaymentSubmission amount(int amount) => call(amount: amount);

  @override
  PaymentSubmission method(PaymentMethodKind method) => call(method: method);

  @override
  PaymentSubmission reference(String reference) => call(reference: reference);

  @override
  PaymentSubmission status(PaymentSubmissionStatus status) =>
      call(status: status);

  @override
  PaymentSubmission reviewerId(String? reviewerId) =>
      call(reviewerId: reviewerId);

  @override
  PaymentSubmission reason(String? reason) => call(reason: reason);

  @override
  PaymentSubmission createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  PaymentSubmission reviewedAt(DateTime? reviewedAt) =>
      call(reviewedAt: reviewedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentSubmission(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentSubmission(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaymentSubmission call({
    Object? id = const $CopyWithPlaceholder(),
    Object? providerId = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? reviewerId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? reviewedAt = const $CopyWithPlaceholder(),
  }) {
    return PaymentSubmission(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      providerId:
          providerId == const $CopyWithPlaceholder() || providerId == null
          ? _value.providerId
          // ignore: cast_nullable_to_non_nullable
          : providerId as String,
      amount: amount == const $CopyWithPlaceholder() || amount == null
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      method: method == const $CopyWithPlaceholder() || method == null
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as PaymentMethodKind,
      reference: reference == const $CopyWithPlaceholder() || reference == null
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PaymentSubmissionStatus,
      reviewerId: reviewerId == const $CopyWithPlaceholder()
          ? _value.reviewerId
          // ignore: cast_nullable_to_non_nullable
          : reviewerId as String?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      reviewedAt: reviewedAt == const $CopyWithPlaceholder()
          ? _value.reviewedAt
          // ignore: cast_nullable_to_non_nullable
          : reviewedAt as DateTime?,
    );
  }
}

extension $PaymentSubmissionCopyWith on PaymentSubmission {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaymentSubmission.copyWith(...)` or `instanceOfPaymentSubmission.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentSubmissionCWProxy get copyWith =>
      _$PaymentSubmissionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentSubmission _$PaymentSubmissionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PaymentSubmission', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'providerId',
          'amount',
          'method',
          'reference',
          'status',
          'createdAt',
        ],
      );
      final val = PaymentSubmission(
        id: $checkedConvert('id', (v) => v as String),
        providerId: $checkedConvert('providerId', (v) => v as String),
        amount: $checkedConvert('amount', (v) => (v as num).toInt()),
        method: $checkedConvert(
          'method',
          (v) => $enumDecode(_$PaymentMethodKindEnumMap, v),
        ),
        reference: $checkedConvert('reference', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$PaymentSubmissionStatusEnumMap, v),
        ),
        reviewerId: $checkedConvert('reviewerId', (v) => v as String?),
        reason: $checkedConvert('reason', (v) => v as String?),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
        reviewedAt: $checkedConvert(
          'reviewedAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PaymentSubmissionToJson(PaymentSubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'providerId': instance.providerId,
      'amount': instance.amount,
      'method': _$PaymentMethodKindEnumMap[instance.method]!,
      'reference': instance.reference,
      'status': _$PaymentSubmissionStatusEnumMap[instance.status]!,
      'reviewerId': ?instance.reviewerId,
      'reason': ?instance.reason,
      'createdAt': instance.createdAt.toIso8601String(),
      'reviewedAt': ?instance.reviewedAt?.toIso8601String(),
    };

const _$PaymentMethodKindEnumMap = {
  PaymentMethodKind.cashToAgent: 'cash_to_agent',
  PaymentMethodKind.bkash: 'bkash',
  PaymentMethodKind.nagad: 'nagad',
  PaymentMethodKind.bank: 'bank',
};

const _$PaymentSubmissionStatusEnumMap = {
  PaymentSubmissionStatus.pending: 'pending',
  PaymentSubmissionStatus.confirmed: 'confirmed',
  PaymentSubmissionStatus.rejected: 'rejected',
};
