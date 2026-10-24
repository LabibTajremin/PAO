// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_submission_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentSubmissionListCWProxy {
  PaymentSubmissionList items(List<PaymentSubmission> items);

  PaymentSubmissionList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentSubmissionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentSubmissionList(...).copyWith(id: 12, name: "My name")
  /// ```
  PaymentSubmissionList call({
    List<PaymentSubmission> items,
    String? nextCursor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaymentSubmissionList.copyWith(...)` or call `instanceOfPaymentSubmissionList.copyWith.fieldName(value)` for a single field.
class _$PaymentSubmissionListCWProxyImpl
    implements _$PaymentSubmissionListCWProxy {
  const _$PaymentSubmissionListCWProxyImpl(this._value);

  final PaymentSubmissionList _value;

  @override
  PaymentSubmissionList items(List<PaymentSubmission> items) =>
      call(items: items);

  @override
  PaymentSubmissionList nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentSubmissionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentSubmissionList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaymentSubmissionList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return PaymentSubmissionList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PaymentSubmission>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $PaymentSubmissionListCopyWith on PaymentSubmissionList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaymentSubmissionList.copyWith(...)` or `instanceOfPaymentSubmissionList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentSubmissionListCWProxy get copyWith =>
      _$PaymentSubmissionListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentSubmissionList _$PaymentSubmissionListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PaymentSubmissionList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = PaymentSubmissionList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => PaymentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$PaymentSubmissionListToJson(
  PaymentSubmissionList instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};
