// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_card.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderCardCWProxy {
  ProviderCard id(String id);

  ProviderCard name(String name);

  ProviderCard photoUrl(String? photoUrl);

  ProviderCard badge(Badge badge);

  ProviderCard level(int level);

  ProviderCard rating(double rating);

  ProviderCard ratingCount(int ratingCount);

  ProviderCard completedJobs(int completedJobs);

  ProviderCard distanceM(int distanceM);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderCard(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderCard call({
    String id,
    String name,
    String? photoUrl,
    Badge badge,
    int level,
    double rating,
    int ratingCount,
    int completedJobs,
    int distanceM,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderCard.copyWith(...)` or call `instanceOfProviderCard.copyWith.fieldName(value)` for a single field.
class _$ProviderCardCWProxyImpl implements _$ProviderCardCWProxy {
  const _$ProviderCardCWProxyImpl(this._value);

  final ProviderCard _value;

  @override
  ProviderCard id(String id) => call(id: id);

  @override
  ProviderCard name(String name) => call(name: name);

  @override
  ProviderCard photoUrl(String? photoUrl) => call(photoUrl: photoUrl);

  @override
  ProviderCard badge(Badge badge) => call(badge: badge);

  @override
  ProviderCard level(int level) => call(level: level);

  @override
  ProviderCard rating(double rating) => call(rating: rating);

  @override
  ProviderCard ratingCount(int ratingCount) => call(ratingCount: ratingCount);

  @override
  ProviderCard completedJobs(int completedJobs) =>
      call(completedJobs: completedJobs);

  @override
  ProviderCard distanceM(int distanceM) => call(distanceM: distanceM);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderCard(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderCard call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? badge = const $CopyWithPlaceholder(),
    Object? level = const $CopyWithPlaceholder(),
    Object? rating = const $CopyWithPlaceholder(),
    Object? ratingCount = const $CopyWithPlaceholder(),
    Object? completedJobs = const $CopyWithPlaceholder(),
    Object? distanceM = const $CopyWithPlaceholder(),
  }) {
    return ProviderCard(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      photoUrl: photoUrl == const $CopyWithPlaceholder()
          ? _value.photoUrl
          // ignore: cast_nullable_to_non_nullable
          : photoUrl as String?,
      badge: badge == const $CopyWithPlaceholder() || badge == null
          ? _value.badge
          // ignore: cast_nullable_to_non_nullable
          : badge as Badge,
      level: level == const $CopyWithPlaceholder() || level == null
          ? _value.level
          // ignore: cast_nullable_to_non_nullable
          : level as int,
      rating: rating == const $CopyWithPlaceholder() || rating == null
          ? _value.rating
          // ignore: cast_nullable_to_non_nullable
          : rating as double,
      ratingCount:
          ratingCount == const $CopyWithPlaceholder() || ratingCount == null
          ? _value.ratingCount
          // ignore: cast_nullable_to_non_nullable
          : ratingCount as int,
      completedJobs:
          completedJobs == const $CopyWithPlaceholder() || completedJobs == null
          ? _value.completedJobs
          // ignore: cast_nullable_to_non_nullable
          : completedJobs as int,
      distanceM: distanceM == const $CopyWithPlaceholder() || distanceM == null
          ? _value.distanceM
          // ignore: cast_nullable_to_non_nullable
          : distanceM as int,
    );
  }
}

extension $ProviderCardCopyWith on ProviderCard {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderCard.copyWith(...)` or `instanceOfProviderCard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderCardCWProxy get copyWith => _$ProviderCardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderCard _$ProviderCardFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProviderCard', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'badge',
          'level',
          'rating',
          'ratingCount',
          'completedJobs',
          'distanceM',
        ],
      );
      final val = ProviderCard(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        photoUrl: $checkedConvert('photoUrl', (v) => v as String?),
        badge: $checkedConvert('badge', (v) => $enumDecode(_$BadgeEnumMap, v)),
        level: $checkedConvert('level', (v) => (v as num).toInt()),
        rating: $checkedConvert('rating', (v) => (v as num).toDouble()),
        ratingCount: $checkedConvert('ratingCount', (v) => (v as num).toInt()),
        completedJobs: $checkedConvert(
          'completedJobs',
          (v) => (v as num).toInt(),
        ),
        distanceM: $checkedConvert('distanceM', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ProviderCardToJson(ProviderCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'photoUrl': ?instance.photoUrl,
      'badge': _$BadgeEnumMap[instance.badge]!,
      'level': instance.level,
      'rating': instance.rating,
      'ratingCount': instance.ratingCount,
      'completedJobs': instance.completedJobs,
      'distanceM': instance.distanceM,
    };

const _$BadgeEnumMap = {
  Badge.none: 'none',
  Badge.verified: 'verified',
  Badge.verifiedPro: 'verified_pro',
};
