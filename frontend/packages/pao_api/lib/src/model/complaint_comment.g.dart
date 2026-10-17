// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_comment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComplaintCommentCWProxy {
  ComplaintComment authorId(String authorId);

  ComplaintComment body(String body);

  ComplaintComment at(DateTime at);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintComment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintComment(...).copyWith(id: 12, name: "My name")
  /// ```
  ComplaintComment call({String authorId, String body, DateTime at});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComplaintComment.copyWith(...)` or call `instanceOfComplaintComment.copyWith.fieldName(value)` for a single field.
class _$ComplaintCommentCWProxyImpl implements _$ComplaintCommentCWProxy {
  const _$ComplaintCommentCWProxyImpl(this._value);

  final ComplaintComment _value;

  @override
  ComplaintComment authorId(String authorId) => call(authorId: authorId);

  @override
  ComplaintComment body(String body) => call(body: body);

  @override
  ComplaintComment at(DateTime at) => call(at: at);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintComment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintComment(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComplaintComment call({
    Object? authorId = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
  }) {
    return ComplaintComment(
      authorId: authorId == const $CopyWithPlaceholder() || authorId == null
          ? _value.authorId
          // ignore: cast_nullable_to_non_nullable
          : authorId as String,
      body: body == const $CopyWithPlaceholder() || body == null
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
    );
  }
}

extension $ComplaintCommentCopyWith on ComplaintComment {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComplaintComment.copyWith(...)` or `instanceOfComplaintComment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComplaintCommentCWProxy get copyWith => _$ComplaintCommentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintComment _$ComplaintCommentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComplaintComment', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['authorId', 'body', 'at']);
      final val = ComplaintComment(
        authorId: $checkedConvert('authorId', (v) => v as String),
        body: $checkedConvert('body', (v) => v as String),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
      );
      return val;
    });

Map<String, dynamic> _$ComplaintCommentToJson(ComplaintComment instance) =>
    <String, dynamic>{
      'authorId': instance.authorId,
      'body': instance.body,
      'at': instance.at.toIso8601String(),
    };
