// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_document.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewDocumentCWProxy {
  ReviewDocument mediaId(String mediaId);

  ReviewDocument kind(String kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewDocument(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewDocument(...).copyWith(id: 12, name: "My name")
  /// ```
  ReviewDocument call({String mediaId, String kind});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReviewDocument.copyWith(...)` or call `instanceOfReviewDocument.copyWith.fieldName(value)` for a single field.
class _$ReviewDocumentCWProxyImpl implements _$ReviewDocumentCWProxy {
  const _$ReviewDocumentCWProxyImpl(this._value);

  final ReviewDocument _value;

  @override
  ReviewDocument mediaId(String mediaId) => call(mediaId: mediaId);

  @override
  ReviewDocument kind(String kind) => call(kind: kind);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewDocument(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewDocument(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReviewDocument call({
    Object? mediaId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
  }) {
    return ReviewDocument(
      mediaId: mediaId == const $CopyWithPlaceholder() || mediaId == null
          ? _value.mediaId
          // ignore: cast_nullable_to_non_nullable
          : mediaId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
    );
  }
}

extension $ReviewDocumentCopyWith on ReviewDocument {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReviewDocument.copyWith(...)` or `instanceOfReviewDocument.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewDocumentCWProxy get copyWith => _$ReviewDocumentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewDocument _$ReviewDocumentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewDocument', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['mediaId', 'kind']);
      final val = ReviewDocument(
        mediaId: $checkedConvert('mediaId', (v) => v as String),
        kind: $checkedConvert('kind', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ReviewDocumentToJson(ReviewDocument instance) =>
    <String, dynamic>{'mediaId': instance.mediaId, 'kind': instance.kind};
