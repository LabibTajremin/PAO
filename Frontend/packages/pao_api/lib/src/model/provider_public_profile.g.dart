// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_public_profile.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderPublicProfileCWProxy {
  ProviderPublicProfile id(String id);

  ProviderPublicProfile name(String name);

  ProviderPublicProfile photoUrl(String? photoUrl);

  ProviderPublicProfile badge(Badge badge);

  ProviderPublicProfile level(int level);

  ProviderPublicProfile bio(String bio);

  ProviderPublicProfile experienceYears(int experienceYears);

  ProviderPublicProfile services(List<ServiceRef> services);

  ProviderPublicProfile rating(RatingBreakdown rating);

  ProviderPublicProfile completedJobs(int completedJobs);

  ProviderPublicProfile memberSince(DateTime memberSince);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderPublicProfile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderPublicProfile(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderPublicProfile call({
    String id,
    String name,
    String? photoUrl,
    Badge badge,
    int level,
    String bio,
    int experienceYears,
    List<ServiceRef> services,
    RatingBreakdown rating,
    int completedJobs,
    DateTime memberSince,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderPublicProfile.copyWith(...)` or call `instanceOfProviderPublicProfile.copyWith.fieldName(value)` for a single field.
class _$ProviderPublicProfileCWProxyImpl
    implements _$ProviderPublicProfileCWProxy {
  const _$ProviderPublicProfileCWProxyImpl(this._value);

  final ProviderPublicProfile _value;

  @override
  ProviderPublicProfile id(String id) => call(id: id);

  @override
  ProviderPublicProfile name(String name) => call(name: name);

  @override
  ProviderPublicProfile photoUrl(String? photoUrl) => call(photoUrl: photoUrl);

  @override
  ProviderPublicProfile badge(Badge badge) => call(badge: badge);

  @override
  ProviderPublicProfile level(int level) => call(level: level);

  @override
  ProviderPublicProfile bio(String bio) => call(bio: bio);

  @override
  ProviderPublicProfile experienceYears(int experienceYears) =>
      call(experienceYears: experienceYears);

  @override
  ProviderPublicProfile services(List<ServiceRef> services) =>
      call(services: services);

  @override
  ProviderPublicProfile rating(RatingBreakdown rating) => call(rating: rating);

  @override
  ProviderPublicProfile completedJobs(int completedJobs) =>
      call(completedJobs: completedJobs);

  @override
  ProviderPublicProfile memberSince(DateTime memberSince) =>
      call(memberSince: memberSince);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderPublicProfile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderPublicProfile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderPublicProfile call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? badge = const $CopyWithPlaceholder(),
    Object? level = const $CopyWithPlaceholder(),
    Object? bio = const $CopyWithPlaceholder(),
    Object? experienceYears = const $CopyWithPlaceholder(),
    Object? services = const $CopyWithPlaceholder(),
    Object? rating = const $CopyWithPlaceholder(),
    Object? completedJobs = const $CopyWithPlaceholder(),
    Object? memberSince = const $CopyWithPlaceholder(),
  }) {
    return ProviderPublicProfile(
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
      bio: bio == const $CopyWithPlaceholder() || bio == null
          ? _value.bio
          // ignore: cast_nullable_to_non_nullable
          : bio as String,
      experienceYears:
          experienceYears == const $CopyWithPlaceholder() ||
              experienceYears == null
          ? _value.experienceYears
          // ignore: cast_nullable_to_non_nullable
          : experienceYears as int,
      services: services == const $CopyWithPlaceholder() || services == null
          ? _value.services
          // ignore: cast_nullable_to_non_nullable
          : services as List<ServiceRef>,
      rating: rating == const $CopyWithPlaceholder() || rating == null
          ? _value.rating
          // ignore: cast_nullable_to_non_nullable
          : rating as RatingBreakdown,
      completedJobs:
          completedJobs == const $CopyWithPlaceholder() || completedJobs == null
          ? _value.completedJobs
          // ignore: cast_nullable_to_non_nullable
          : completedJobs as int,
      memberSince:
          memberSince == const $CopyWithPlaceholder() || memberSince == null
          ? _value.memberSince
          // ignore: cast_nullable_to_non_nullable
          : memberSince as DateTime,
    );
  }
}

extension $ProviderPublicProfileCopyWith on ProviderPublicProfile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderPublicProfile.copyWith(...)` or `instanceOfProviderPublicProfile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderPublicProfileCWProxy get copyWith =>
      _$ProviderPublicProfileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderPublicProfile _$ProviderPublicProfileFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProviderPublicProfile', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'name',
      'badge',
      'level',
      'bio',
      'experienceYears',
      'services',
      'rating',
      'completedJobs',
      'memberSince',
    ],
  );
  final val = ProviderPublicProfile(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    photoUrl: $checkedConvert('photoUrl', (v) => v as String?),
    badge: $checkedConvert('badge', (v) => $enumDecode(_$BadgeEnumMap, v)),
    level: $checkedConvert('level', (v) => (v as num).toInt()),
    bio: $checkedConvert('bio', (v) => v as String),
    experienceYears: $checkedConvert(
      'experienceYears',
      (v) => (v as num).toInt(),
    ),
    services: $checkedConvert(
      'services',
      (v) => (v as List<dynamic>)
          .map((e) => ServiceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    rating: $checkedConvert(
      'rating',
      (v) => RatingBreakdown.fromJson(v as Map<String, dynamic>),
    ),
    completedJobs: $checkedConvert('completedJobs', (v) => (v as num).toInt()),
    memberSince: $checkedConvert(
      'memberSince',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
});

Map<String, dynamic> _$ProviderPublicProfileToJson(
  ProviderPublicProfile instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'photoUrl': ?instance.photoUrl,
  'badge': _$BadgeEnumMap[instance.badge]!,
  'level': instance.level,
  'bio': instance.bio,
  'experienceYears': instance.experienceYears,
  'services': instance.services.map((e) => e.toJson()).toList(),
  'rating': instance.rating.toJson(),
  'completedJobs': instance.completedJobs,
  'memberSince': instance.memberSince.toIso8601String(),
};

const _$BadgeEnumMap = {
  Badge.none: 'none',
  Badge.verified: 'verified',
  Badge.verifiedPro: 'verified_pro',
};
