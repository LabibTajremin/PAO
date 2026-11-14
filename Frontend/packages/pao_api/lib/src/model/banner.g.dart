// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BannerCWProxy {
  Banner id(String id);

  Banner title(LocalizedText title);

  Banner subtitle(LocalizedText? subtitle);

  Banner imageUrl(String? imageUrl);

  Banner serviceId(String? serviceId);

  Banner sortOrder(int sortOrder);

  Banner published(bool published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Banner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Banner(...).copyWith(id: 12, name: "My name")
  /// ```
  Banner call({
    String id,
    LocalizedText title,
    LocalizedText? subtitle,
    String? imageUrl,
    String? serviceId,
    int sortOrder,
    bool published,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBanner.copyWith(...)` or call `instanceOfBanner.copyWith.fieldName(value)` for a single field.
class _$BannerCWProxyImpl implements _$BannerCWProxy {
  const _$BannerCWProxyImpl(this._value);

  final Banner _value;

  @override
  Banner id(String id) => call(id: id);

  @override
  Banner title(LocalizedText title) => call(title: title);

  @override
  Banner subtitle(LocalizedText? subtitle) => call(subtitle: subtitle);

  @override
  Banner imageUrl(String? imageUrl) => call(imageUrl: imageUrl);

  @override
  Banner serviceId(String? serviceId) => call(serviceId: serviceId);

  @override
  Banner sortOrder(int sortOrder) => call(sortOrder: sortOrder);

  @override
  Banner published(bool published) => call(published: published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Banner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Banner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Banner call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? subtitle = const $CopyWithPlaceholder(),
    Object? imageUrl = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? sortOrder = const $CopyWithPlaceholder(),
    Object? published = const $CopyWithPlaceholder(),
  }) {
    return Banner(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as LocalizedText,
      subtitle: subtitle == const $CopyWithPlaceholder()
          ? _value.subtitle
          // ignore: cast_nullable_to_non_nullable
          : subtitle as LocalizedText?,
      imageUrl: imageUrl == const $CopyWithPlaceholder()
          ? _value.imageUrl
          // ignore: cast_nullable_to_non_nullable
          : imageUrl as String?,
      serviceId: serviceId == const $CopyWithPlaceholder()
          ? _value.serviceId
          // ignore: cast_nullable_to_non_nullable
          : serviceId as String?,
      sortOrder: sortOrder == const $CopyWithPlaceholder() || sortOrder == null
          ? _value.sortOrder
          // ignore: cast_nullable_to_non_nullable
          : sortOrder as int,
      published: published == const $CopyWithPlaceholder() || published == null
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool,
    );
  }
}

extension $BannerCopyWith on Banner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBanner.copyWith(...)` or `instanceOfBanner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BannerCWProxy get copyWith => _$BannerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Banner _$BannerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Banner', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'title', 'sortOrder', 'published'],
      );
      final val = Banner(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert(
          'title',
          (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
        subtitle: $checkedConvert(
          'subtitle',
          (v) => v == null
              ? null
              : LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
        imageUrl: $checkedConvert('imageUrl', (v) => v as String?),
        serviceId: $checkedConvert('serviceId', (v) => v as String?),
        sortOrder: $checkedConvert('sortOrder', (v) => (v as num).toInt()),
        published: $checkedConvert('published', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$BannerToJson(Banner instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title.toJson(),
  'subtitle': ?instance.subtitle?.toJson(),
  'imageUrl': ?instance.imageUrl,
  'serviceId': ?instance.serviceId,
  'sortOrder': instance.sortOrder,
  'published': instance.published,
};
