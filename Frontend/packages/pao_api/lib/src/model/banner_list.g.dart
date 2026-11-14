// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BannerListCWProxy {
  BannerList banners(List<Banner> banners);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BannerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BannerList(...).copyWith(id: 12, name: "My name")
  /// ```
  BannerList call({List<Banner> banners});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBannerList.copyWith(...)` or call `instanceOfBannerList.copyWith.fieldName(value)` for a single field.
class _$BannerListCWProxyImpl implements _$BannerListCWProxy {
  const _$BannerListCWProxyImpl(this._value);

  final BannerList _value;

  @override
  BannerList banners(List<Banner> banners) => call(banners: banners);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BannerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BannerList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BannerList call({Object? banners = const $CopyWithPlaceholder()}) {
    return BannerList(
      banners: banners == const $CopyWithPlaceholder() || banners == null
          ? _value.banners
          // ignore: cast_nullable_to_non_nullable
          : banners as List<Banner>,
    );
  }
}

extension $BannerListCopyWith on BannerList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBannerList.copyWith(...)` or `instanceOfBannerList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BannerListCWProxy get copyWith => _$BannerListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BannerList _$BannerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BannerList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['banners']);
      final val = BannerList(
        banners: $checkedConvert(
          'banners',
          (v) => (v as List<dynamic>)
              .map((e) => Banner.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BannerListToJson(BannerList instance) =>
    <String, dynamic>{
      'banners': instance.banners.map((e) => e.toJson()).toList(),
    };
