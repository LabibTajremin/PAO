// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppConfigCWProxy {
  AppConfig tagline(LocalizedText tagline);

  AppConfig artwork(List<ArtworkImage> artwork);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  AppConfig call({LocalizedText tagline, List<ArtworkImage> artwork});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppConfig.copyWith(...)` or call `instanceOfAppConfig.copyWith.fieldName(value)` for a single field.
class _$AppConfigCWProxyImpl implements _$AppConfigCWProxy {
  const _$AppConfigCWProxyImpl(this._value);

  final AppConfig _value;

  @override
  AppConfig tagline(LocalizedText tagline) => call(tagline: tagline);

  @override
  AppConfig artwork(List<ArtworkImage> artwork) => call(artwork: artwork);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppConfig call({
    Object? tagline = const $CopyWithPlaceholder(),
    Object? artwork = const $CopyWithPlaceholder(),
  }) {
    return AppConfig(
      tagline: tagline == const $CopyWithPlaceholder() || tagline == null
          ? _value.tagline
          // ignore: cast_nullable_to_non_nullable
          : tagline as LocalizedText,
      artwork: artwork == const $CopyWithPlaceholder() || artwork == null
          ? _value.artwork
          // ignore: cast_nullable_to_non_nullable
          : artwork as List<ArtworkImage>,
    );
  }
}

extension $AppConfigCopyWith on AppConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppConfig.copyWith(...)` or `instanceOfAppConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppConfigCWProxy get copyWith => _$AppConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppConfig', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['tagline', 'artwork']);
      final val = AppConfig(
        tagline: $checkedConvert(
          'tagline',
          (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
        artwork: $checkedConvert(
          'artwork',
          (v) => (v as List<dynamic>)
              .map((e) => ArtworkImage.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
  'tagline': instance.tagline.toJson(),
  'artwork': instance.artwork.map((e) => e.toJson()).toList(),
};
