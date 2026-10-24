// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComplaintInputCWProxy {
  ComplaintInput reason(ComplaintReason reason);

  ComplaintInput description(String description);

  ComplaintInput photoMediaIds(List<String>? photoMediaIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ComplaintInput call({
    ComplaintReason reason,
    String description,
    List<String>? photoMediaIds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComplaintInput.copyWith(...)` or call `instanceOfComplaintInput.copyWith.fieldName(value)` for a single field.
class _$ComplaintInputCWProxyImpl implements _$ComplaintInputCWProxy {
  const _$ComplaintInputCWProxyImpl(this._value);

  final ComplaintInput _value;

  @override
  ComplaintInput reason(ComplaintReason reason) => call(reason: reason);

  @override
  ComplaintInput description(String description) =>
      call(description: description);

  @override
  ComplaintInput photoMediaIds(List<String>? photoMediaIds) =>
      call(photoMediaIds: photoMediaIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComplaintInput call({
    Object? reason = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? photoMediaIds = const $CopyWithPlaceholder(),
  }) {
    return ComplaintInput(
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as ComplaintReason,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      photoMediaIds: photoMediaIds == const $CopyWithPlaceholder()
          ? _value.photoMediaIds
          // ignore: cast_nullable_to_non_nullable
          : photoMediaIds as List<String>?,
    );
  }
}

extension $ComplaintInputCopyWith on ComplaintInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComplaintInput.copyWith(...)` or `instanceOfComplaintInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComplaintInputCWProxy get copyWith => _$ComplaintInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintInput _$ComplaintInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComplaintInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason', 'description']);
      final val = ComplaintInput(
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$ComplaintReasonEnumMap, v),
        ),
        description: $checkedConvert('description', (v) => v as String),
        photoMediaIds: $checkedConvert(
          'photoMediaIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ComplaintInputToJson(ComplaintInput instance) =>
    <String, dynamic>{
      'reason': _$ComplaintReasonEnumMap[instance.reason]!,
      'description': instance.description,
      'photoMediaIds': ?instance.photoMediaIds,
    };

const _$ComplaintReasonEnumMap = {
  ComplaintReason.noShow: 'no_show',
  ComplaintReason.late_: 'late',
  ComplaintReason.poorQuality: 'poor_quality',
  ComplaintReason.overcharge: 'overcharge',
  ComplaintReason.damage: 'damage',
  ComplaintReason.behaviour: 'behaviour',
  ComplaintReason.safety: 'safety',
  ComplaintReason.customerUnavailable: 'customer_unavailable',
  ComplaintReason.payment: 'payment',
  ComplaintReason.other: 'other',
};
