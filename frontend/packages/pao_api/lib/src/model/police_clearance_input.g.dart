// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'police_clearance_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PoliceClearanceInputCWProxy {
  PoliceClearanceInput mediaId(String mediaId);

  PoliceClearanceInput issueDate(String issueDate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PoliceClearanceInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PoliceClearanceInput(...).copyWith(id: 12, name: "My name")
  /// ```
  PoliceClearanceInput call({String mediaId, String issueDate});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPoliceClearanceInput.copyWith(...)` or call `instanceOfPoliceClearanceInput.copyWith.fieldName(value)` for a single field.
class _$PoliceClearanceInputCWProxyImpl
    implements _$PoliceClearanceInputCWProxy {
  const _$PoliceClearanceInputCWProxyImpl(this._value);

  final PoliceClearanceInput _value;

  @override
  PoliceClearanceInput mediaId(String mediaId) => call(mediaId: mediaId);

  @override
  PoliceClearanceInput issueDate(String issueDate) =>
      call(issueDate: issueDate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PoliceClearanceInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PoliceClearanceInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PoliceClearanceInput call({
    Object? mediaId = const $CopyWithPlaceholder(),
    Object? issueDate = const $CopyWithPlaceholder(),
  }) {
    return PoliceClearanceInput(
      mediaId: mediaId == const $CopyWithPlaceholder() || mediaId == null
          ? _value.mediaId
          // ignore: cast_nullable_to_non_nullable
          : mediaId as String,
      issueDate: issueDate == const $CopyWithPlaceholder() || issueDate == null
          ? _value.issueDate
          // ignore: cast_nullable_to_non_nullable
          : issueDate as String,
    );
  }
}

extension $PoliceClearanceInputCopyWith on PoliceClearanceInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPoliceClearanceInput.copyWith(...)` or `instanceOfPoliceClearanceInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PoliceClearanceInputCWProxy get copyWith =>
      _$PoliceClearanceInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PoliceClearanceInput _$PoliceClearanceInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PoliceClearanceInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mediaId', 'issueDate']);
  final val = PoliceClearanceInput(
    mediaId: $checkedConvert('mediaId', (v) => v as String),
    issueDate: $checkedConvert('issueDate', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$PoliceClearanceInputToJson(
  PoliceClearanceInput instance,
) => <String, dynamic>{
  'mediaId': instance.mediaId,
  'issueDate': instance.issueDate,
};
