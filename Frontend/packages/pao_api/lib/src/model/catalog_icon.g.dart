// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_icon.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CatalogIconCWProxy {
  CatalogIcon iconUrl(String iconUrl);

  CatalogIcon contentType(CatalogIconContentTypeEnum contentType);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogIcon(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogIcon(...).copyWith(id: 12, name: "My name")
  /// ```
  CatalogIcon call({String iconUrl, CatalogIconContentTypeEnum contentType});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCatalogIcon.copyWith(...)` or call `instanceOfCatalogIcon.copyWith.fieldName(value)` for a single field.
class _$CatalogIconCWProxyImpl implements _$CatalogIconCWProxy {
  const _$CatalogIconCWProxyImpl(this._value);

  final CatalogIcon _value;

  @override
  CatalogIcon iconUrl(String iconUrl) => call(iconUrl: iconUrl);

  @override
  CatalogIcon contentType(CatalogIconContentTypeEnum contentType) =>
      call(contentType: contentType);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogIcon(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogIcon(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CatalogIcon call({
    Object? iconUrl = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
  }) {
    return CatalogIcon(
      iconUrl: iconUrl == const $CopyWithPlaceholder() || iconUrl == null
          ? _value.iconUrl
          // ignore: cast_nullable_to_non_nullable
          : iconUrl as String,
      contentType:
          contentType == const $CopyWithPlaceholder() || contentType == null
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as CatalogIconContentTypeEnum,
    );
  }
}

extension $CatalogIconCopyWith on CatalogIcon {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCatalogIcon.copyWith(...)` or `instanceOfCatalogIcon.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CatalogIconCWProxy get copyWith => _$CatalogIconCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogIcon _$CatalogIconFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CatalogIcon', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['iconUrl', 'contentType']);
      final val = CatalogIcon(
        iconUrl: $checkedConvert('iconUrl', (v) => v as String),
        contentType: $checkedConvert(
          'contentType',
          (v) => $enumDecode(_$CatalogIconContentTypeEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CatalogIconToJson(CatalogIcon instance) =>
    <String, dynamic>{
      'iconUrl': instance.iconUrl,
      'contentType': _$CatalogIconContentTypeEnumEnumMap[instance.contentType]!,
    };

const _$CatalogIconContentTypeEnumEnumMap = {
  CatalogIconContentTypeEnum.imageSlashSvgPlusXml: 'image/svg+xml',
  CatalogIconContentTypeEnum.imageSlashPng: 'image/png',
  CatalogIconContentTypeEnum.imageSlashWebp: 'image/webp',
};
