// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_comment_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComplaintCommentInputCWProxy {
  ComplaintCommentInput body(String body);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintCommentInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintCommentInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ComplaintCommentInput call({String body});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComplaintCommentInput.copyWith(...)` or call `instanceOfComplaintCommentInput.copyWith.fieldName(value)` for a single field.
class _$ComplaintCommentInputCWProxyImpl
    implements _$ComplaintCommentInputCWProxy {
  const _$ComplaintCommentInputCWProxyImpl(this._value);

  final ComplaintCommentInput _value;

  @override
  ComplaintCommentInput body(String body) => call(body: body);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintCommentInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintCommentInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComplaintCommentInput call({Object? body = const $CopyWithPlaceholder()}) {
    return ComplaintCommentInput(
      body: body == const $CopyWithPlaceholder() || body == null
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
    );
  }
}

extension $ComplaintCommentInputCopyWith on ComplaintCommentInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComplaintCommentInput.copyWith(...)` or `instanceOfComplaintCommentInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComplaintCommentInputCWProxy get copyWith =>
      _$ComplaintCommentInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintCommentInput _$ComplaintCommentInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ComplaintCommentInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['body']);
  final val = ComplaintCommentInput(
    body: $checkedConvert('body', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ComplaintCommentInputToJson(
  ComplaintCommentInput instance,
) => <String, dynamic>{'body': instance.body};
