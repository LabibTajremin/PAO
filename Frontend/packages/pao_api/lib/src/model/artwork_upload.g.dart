// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork_upload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ArtworkUploadCWProxy {
  ArtworkUpload contentType(ArtworkUploadContentTypeEnum contentType);

  ArtworkUpload data(String data);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ArtworkUpload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ArtworkUpload(...).copyWith(id: 12, name: "My name")
  /// ```
  ArtworkUpload call({ArtworkUploadContentTypeEnum contentType, String data});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfArtworkUpload.copyWith(...)` or call `instanceOfArtworkUpload.copyWith.fieldName(value)` for a single field.
class _$ArtworkUploadCWProxyImpl implements _$ArtworkUploadCWProxy {
  const _$ArtworkUploadCWProxyImpl(this._value);

  final ArtworkUpload _value;

  @override
  ArtworkUpload contentType(ArtworkUploadContentTypeEnum contentType) =>
      call(contentType: contentType);

  @override
  ArtworkUpload data(String data) => call(data: data);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ArtworkUpload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ArtworkUpload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ArtworkUpload call({
    Object? contentType = const $CopyWithPlaceholder(),
    Object? data = const $CopyWithPlaceholder(),
  }) {
    return ArtworkUpload(
      contentType:
          contentType == const $CopyWithPlaceholder() || contentType == null
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as ArtworkUploadContentTypeEnum,
      data: data == const $CopyWithPlaceholder() || data == null
          ? _value.data
          // ignore: cast_nullable_to_non_nullable
          : data as String,
    );
  }
}

extension $ArtworkUploadCopyWith on ArtworkUpload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfArtworkUpload.copyWith(...)` or `instanceOfArtworkUpload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ArtworkUploadCWProxy get copyWith => _$ArtworkUploadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtworkUpload _$ArtworkUploadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtworkUpload', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['contentType', 'data']);
      final val = ArtworkUpload(
        contentType: $checkedConvert(
          'contentType',
          (v) => $enumDecode(_$ArtworkUploadContentTypeEnumEnumMap, v),
        ),
        data: $checkedConvert('data', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ArtworkUploadToJson(
  ArtworkUpload instance,
) => <String, dynamic>{
  'contentType': _$ArtworkUploadContentTypeEnumEnumMap[instance.contentType]!,
  'data': instance.data,
};

const _$ArtworkUploadContentTypeEnumEnumMap = {
  ArtworkUploadContentTypeEnum.imageSlashSvgPlusXml: 'image/svg+xml',
  ArtworkUploadContentTypeEnum.imageSlashPng: 'image/png',
  ArtworkUploadContentTypeEnum.imageSlashWebp: 'image/webp',
};
