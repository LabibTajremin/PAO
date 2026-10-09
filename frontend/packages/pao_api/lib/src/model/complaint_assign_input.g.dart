// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_assign_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComplaintAssignInputCWProxy {
  ComplaintAssignInput assigneeId(String assigneeId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintAssignInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintAssignInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ComplaintAssignInput call({String assigneeId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComplaintAssignInput.copyWith(...)` or call `instanceOfComplaintAssignInput.copyWith.fieldName(value)` for a single field.
class _$ComplaintAssignInputCWProxyImpl
    implements _$ComplaintAssignInputCWProxy {
  const _$ComplaintAssignInputCWProxyImpl(this._value);

  final ComplaintAssignInput _value;

  @override
  ComplaintAssignInput assigneeId(String assigneeId) =>
      call(assigneeId: assigneeId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintAssignInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintAssignInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComplaintAssignInput call({
    Object? assigneeId = const $CopyWithPlaceholder(),
  }) {
    return ComplaintAssignInput(
      assigneeId:
          assigneeId == const $CopyWithPlaceholder() || assigneeId == null
          ? _value.assigneeId
          // ignore: cast_nullable_to_non_nullable
          : assigneeId as String,
    );
  }
}

extension $ComplaintAssignInputCopyWith on ComplaintAssignInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComplaintAssignInput.copyWith(...)` or `instanceOfComplaintAssignInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComplaintAssignInputCWProxy get copyWith =>
      _$ComplaintAssignInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintAssignInput _$ComplaintAssignInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ComplaintAssignInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['assigneeId']);
  final val = ComplaintAssignInput(
    assigneeId: $checkedConvert('assigneeId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ComplaintAssignInputToJson(
  ComplaintAssignInput instance,
) => <String, dynamic>{'assigneeId': instance.assigneeId};
