// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BannerInputCWProxy {
  BannerInput title(LocalizedText title);

  BannerInput subtitle(LocalizedText? subtitle);

  BannerInput imageUrl(String? imageUrl);

  BannerInput serviceId(String? serviceId);

  BannerInput sortOrder(int? sortOrder);

  BannerInput published(bool? published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BannerInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BannerInput(...).copyWith(id: 12, name: "My name")
  /// ```
  BannerInput call({
    LocalizedText title,
    LocalizedText? subtitle,
    String? imageUrl,
    String? serviceId,
    int? sortOrder,
    bool? published,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBannerInput.copyWith(...)` or call `instanceOfBannerInput.copyWith.fieldName(value)` for a single field.
class _$BannerInputCWProxyImpl implements _$BannerInputCWProxy {
  const _$BannerInputCWProxyImpl(this._value);

  final BannerInput _value;

  @override
  BannerInput title(LocalizedText title) => call(title: title);

  @override
  BannerInput subtitle(LocalizedText? subtitle) => call(subtitle: subtitle);

  @override
  BannerInput imageUrl(String? imageUrl) => call(imageUrl: imageUrl);

  @override
  BannerInput serviceId(String? serviceId) => call(serviceId: serviceId);

  @override
  BannerInput sortOrder(int? sortOrder) => call(sortOrder: sortOrder);

  @override
  BannerInput published(bool? published) => call(published: published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BannerInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BannerInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BannerInput call({
    Object? title = const $CopyWithPlaceholder(),
    Object? subtitle = const $CopyWithPlaceholder(),
    Object? imageUrl = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? sortOrder = const $CopyWithPlaceholder(),
    Object? published = const $CopyWithPlaceholder(),
  }) {
    return BannerInput(
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
      sortOrder: sortOrder == const $CopyWithPlaceholder()
          ? _value.sortOrder
          // ignore: cast_nullable_to_non_nullable
          : sortOrder as int?,
      published: published == const $CopyWithPlaceholder()
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool?,
    );
  }
}

extension $BannerInputCopyWith on BannerInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBannerInput.copyWith(...)` or `instanceOfBannerInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BannerInputCWProxy get copyWith => _$BannerInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BannerInput _$BannerInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BannerInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title']);
      final val = BannerInput(
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
        sortOrder: $checkedConvert('sortOrder', (v) => (v as num?)?.toInt()),
        published: $checkedConvert('published', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$BannerInputToJson(BannerInput instance) =>
    <String, dynamic>{
      'title': instance.title.toJson(),
      'subtitle': ?instance.subtitle?.toJson(),
      'imageUrl': ?instance.imageUrl,
      'serviceId': ?instance.serviceId,
      'sortOrder': ?instance.sortOrder,
      'published': ?instance.published,
    };
