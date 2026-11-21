// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'icon_upload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IconUploadCWProxy {
  IconUpload contentType(IconUploadContentTypeEnum contentType);

  IconUpload data(String data);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IconUpload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IconUpload(...).copyWith(id: 12, name: "My name")
  /// ```
  IconUpload call({IconUploadContentTypeEnum contentType, String data});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIconUpload.copyWith(...)` or call `instanceOfIconUpload.copyWith.fieldName(value)` for a single field.
class _$IconUploadCWProxyImpl implements _$IconUploadCWProxy {
  const _$IconUploadCWProxyImpl(this._value);

  final IconUpload _value;

  @override
  IconUpload contentType(IconUploadContentTypeEnum contentType) =>
      call(contentType: contentType);

  @override
  IconUpload data(String data) => call(data: data);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IconUpload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IconUpload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IconUpload call({
    Object? contentType = const $CopyWithPlaceholder(),
    Object? data = const $CopyWithPlaceholder(),
  }) {
    return IconUpload(
      contentType:
          contentType == const $CopyWithPlaceholder() || contentType == null
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as IconUploadContentTypeEnum,
      data: data == const $CopyWithPlaceholder() || data == null
          ? _value.data
          // ignore: cast_nullable_to_non_nullable
          : data as String,
    );
  }
}

extension $IconUploadCopyWith on IconUpload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIconUpload.copyWith(...)` or `instanceOfIconUpload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IconUploadCWProxy get copyWith => _$IconUploadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IconUpload _$IconUploadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IconUpload', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['contentType', 'data']);
      final val = IconUpload(
        contentType: $checkedConvert(
          'contentType',
          (v) => $enumDecode(_$IconUploadContentTypeEnumEnumMap, v),
        ),
        data: $checkedConvert('data', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$IconUploadToJson(IconUpload instance) =>
    <String, dynamic>{
      'contentType': _$IconUploadContentTypeEnumEnumMap[instance.contentType]!,
      'data': instance.data,
    };

const _$IconUploadContentTypeEnumEnumMap = {
  IconUploadContentTypeEnum.imageSlashSvgPlusXml: 'image/svg+xml',
  IconUploadContentTypeEnum.imageSlashPng: 'image/png',
  IconUploadContentTypeEnum.imageSlashWebp: 'image/webp',
};
