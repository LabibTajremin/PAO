// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork_image.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ArtworkImageCWProxy {
  ArtworkImage key(String key);

  ArtworkImage url(String url);

  ArtworkImage version(int version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ArtworkImage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ArtworkImage(...).copyWith(id: 12, name: "My name")
  /// ```
  ArtworkImage call({String key, String url, int version});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfArtworkImage.copyWith(...)` or call `instanceOfArtworkImage.copyWith.fieldName(value)` for a single field.
class _$ArtworkImageCWProxyImpl implements _$ArtworkImageCWProxy {
  const _$ArtworkImageCWProxyImpl(this._value);

  final ArtworkImage _value;

  @override
  ArtworkImage key(String key) => call(key: key);

  @override
  ArtworkImage url(String url) => call(url: url);

  @override
  ArtworkImage version(int version) => call(version: version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ArtworkImage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ArtworkImage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ArtworkImage call({
    Object? key = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return ArtworkImage(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $ArtworkImageCopyWith on ArtworkImage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfArtworkImage.copyWith(...)` or `instanceOfArtworkImage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ArtworkImageCWProxy get copyWith => _$ArtworkImageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtworkImage _$ArtworkImageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtworkImage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['key', 'url', 'version']);
      final val = ArtworkImage(
        key: $checkedConvert('key', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ArtworkImageToJson(ArtworkImage instance) =>
    <String, dynamic>{
      'key': instance.key,
      'url': instance.url,
      'version': instance.version,
    };
