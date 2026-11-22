// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork_slot.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ArtworkSlotCWProxy {
  ArtworkSlot key(String key);

  ArtworkSlot app(AppName app);

  ArtworkSlot width(int width);

  ArtworkSlot height(int height);

  ArtworkSlot url(String? url);

  ArtworkSlot contentType(ArtworkSlotContentTypeEnum? contentType);

  ArtworkSlot version(int version);

  ArtworkSlot replaced(bool replaced);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ArtworkSlot(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ArtworkSlot(...).copyWith(id: 12, name: "My name")
  /// ```
  ArtworkSlot call({
    String key,
    AppName app,
    int width,
    int height,
    String? url,
    ArtworkSlotContentTypeEnum? contentType,
    int version,
    bool replaced,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfArtworkSlot.copyWith(...)` or call `instanceOfArtworkSlot.copyWith.fieldName(value)` for a single field.
class _$ArtworkSlotCWProxyImpl implements _$ArtworkSlotCWProxy {
  const _$ArtworkSlotCWProxyImpl(this._value);

  final ArtworkSlot _value;

  @override
  ArtworkSlot key(String key) => call(key: key);

  @override
  ArtworkSlot app(AppName app) => call(app: app);

  @override
  ArtworkSlot width(int width) => call(width: width);

  @override
  ArtworkSlot height(int height) => call(height: height);

  @override
  ArtworkSlot url(String? url) => call(url: url);

  @override
  ArtworkSlot contentType(ArtworkSlotContentTypeEnum? contentType) =>
      call(contentType: contentType);

  @override
  ArtworkSlot version(int version) => call(version: version);

  @override
  ArtworkSlot replaced(bool replaced) => call(replaced: replaced);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ArtworkSlot(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ArtworkSlot(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ArtworkSlot call({
    Object? key = const $CopyWithPlaceholder(),
    Object? app = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? replaced = const $CopyWithPlaceholder(),
  }) {
    return ArtworkSlot(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      app: app == const $CopyWithPlaceholder() || app == null
          ? _value.app
          // ignore: cast_nullable_to_non_nullable
          : app as AppName,
      width: width == const $CopyWithPlaceholder() || width == null
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as int,
      height: height == const $CopyWithPlaceholder() || height == null
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as int,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      contentType: contentType == const $CopyWithPlaceholder()
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as ArtworkSlotContentTypeEnum?,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      replaced: replaced == const $CopyWithPlaceholder() || replaced == null
          ? _value.replaced
          // ignore: cast_nullable_to_non_nullable
          : replaced as bool,
    );
  }
}

extension $ArtworkSlotCopyWith on ArtworkSlot {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfArtworkSlot.copyWith(...)` or `instanceOfArtworkSlot.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ArtworkSlotCWProxy get copyWith => _$ArtworkSlotCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtworkSlot _$ArtworkSlotFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtworkSlot', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'key',
          'app',
          'width',
          'height',
          'version',
          'replaced',
        ],
      );
      final val = ArtworkSlot(
        key: $checkedConvert('key', (v) => v as String),
        app: $checkedConvert('app', (v) => $enumDecode(_$AppNameEnumMap, v)),
        width: $checkedConvert('width', (v) => (v as num).toInt()),
        height: $checkedConvert('height', (v) => (v as num).toInt()),
        url: $checkedConvert('url', (v) => v as String?),
        contentType: $checkedConvert(
          'contentType',
          (v) => $enumDecodeNullable(_$ArtworkSlotContentTypeEnumEnumMap, v),
        ),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        replaced: $checkedConvert('replaced', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ArtworkSlotToJson(ArtworkSlot instance) =>
    <String, dynamic>{
      'key': instance.key,
      'app': _$AppNameEnumMap[instance.app]!,
      'width': instance.width,
      'height': instance.height,
      'url': ?instance.url,
      'contentType': ?_$ArtworkSlotContentTypeEnumEnumMap[instance.contentType],
      'version': instance.version,
      'replaced': instance.replaced,
    };

const _$AppNameEnumMap = {
  AppName.customer: 'customer',
  AppName.partner: 'partner',
  AppName.admin: 'admin',
};

const _$ArtworkSlotContentTypeEnumEnumMap = {
  ArtworkSlotContentTypeEnum.imageSlashSvgPlusXml: 'image/svg+xml',
  ArtworkSlotContentTypeEnum.imageSlashPng: 'image/png',
  ArtworkSlotContentTypeEnum.imageSlashWebp: 'image/webp',
};
