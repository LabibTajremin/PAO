// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extras_decision_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExtrasDecisionInputCWProxy {
  ExtrasDecisionInput proposalId(String proposalId);

  ExtrasDecisionInput approve(bool approve);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExtrasDecisionInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExtrasDecisionInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ExtrasDecisionInput call({String proposalId, bool approve});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfExtrasDecisionInput.copyWith(...)` or call `instanceOfExtrasDecisionInput.copyWith.fieldName(value)` for a single field.
class _$ExtrasDecisionInputCWProxyImpl implements _$ExtrasDecisionInputCWProxy {
  const _$ExtrasDecisionInputCWProxyImpl(this._value);

  final ExtrasDecisionInput _value;

  @override
  ExtrasDecisionInput proposalId(String proposalId) =>
      call(proposalId: proposalId);

  @override
  ExtrasDecisionInput approve(bool approve) => call(approve: approve);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExtrasDecisionInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExtrasDecisionInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ExtrasDecisionInput call({
    Object? proposalId = const $CopyWithPlaceholder(),
    Object? approve = const $CopyWithPlaceholder(),
  }) {
    return ExtrasDecisionInput(
      proposalId:
          proposalId == const $CopyWithPlaceholder() || proposalId == null
          ? _value.proposalId
          // ignore: cast_nullable_to_non_nullable
          : proposalId as String,
      approve: approve == const $CopyWithPlaceholder() || approve == null
          ? _value.approve
          // ignore: cast_nullable_to_non_nullable
          : approve as bool,
    );
  }
}

extension $ExtrasDecisionInputCopyWith on ExtrasDecisionInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfExtrasDecisionInput.copyWith(...)` or `instanceOfExtrasDecisionInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExtrasDecisionInputCWProxy get copyWith =>
      _$ExtrasDecisionInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtrasDecisionInput _$ExtrasDecisionInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExtrasDecisionInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['proposalId', 'approve']);
      final val = ExtrasDecisionInput(
        proposalId: $checkedConvert('proposalId', (v) => v as String),
        approve: $checkedConvert('approve', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ExtrasDecisionInputToJson(
  ExtrasDecisionInput instance,
) => <String, dynamic>{
  'proposalId': instance.proposalId,
  'approve': instance.approve,
};
