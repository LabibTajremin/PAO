// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_review.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VerificationReviewCWProxy {
  VerificationReview providerId(String providerId);

  VerificationReview level(int level);

  VerificationReview profile(VerificationReviewProfile profile);

  VerificationReview faceMatch(VerificationReviewFaceMatchEnum? faceMatch);

  VerificationReview items(List<ReviewItem> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationReview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationReview(...).copyWith(id: 12, name: "My name")
  /// ```
  VerificationReview call({
    String providerId,
    int level,
    VerificationReviewProfile profile,
    VerificationReviewFaceMatchEnum? faceMatch,
    List<ReviewItem> items,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVerificationReview.copyWith(...)` or call `instanceOfVerificationReview.copyWith.fieldName(value)` for a single field.
class _$VerificationReviewCWProxyImpl implements _$VerificationReviewCWProxy {
  const _$VerificationReviewCWProxyImpl(this._value);

  final VerificationReview _value;

  @override
  VerificationReview providerId(String providerId) =>
      call(providerId: providerId);

  @override
  VerificationReview level(int level) => call(level: level);

  @override
  VerificationReview profile(VerificationReviewProfile profile) =>
      call(profile: profile);

  @override
  VerificationReview faceMatch(VerificationReviewFaceMatchEnum? faceMatch) =>
      call(faceMatch: faceMatch);

  @override
  VerificationReview items(List<ReviewItem> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationReview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationReview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VerificationReview call({
    Object? providerId = const $CopyWithPlaceholder(),
    Object? level = const $CopyWithPlaceholder(),
    Object? profile = const $CopyWithPlaceholder(),
    Object? faceMatch = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return VerificationReview(
      providerId:
          providerId == const $CopyWithPlaceholder() || providerId == null
          ? _value.providerId
          // ignore: cast_nullable_to_non_nullable
          : providerId as String,
      level: level == const $CopyWithPlaceholder() || level == null
          ? _value.level
          // ignore: cast_nullable_to_non_nullable
          : level as int,
      profile: profile == const $CopyWithPlaceholder() || profile == null
          ? _value.profile
          // ignore: cast_nullable_to_non_nullable
          : profile as VerificationReviewProfile,
      faceMatch: faceMatch == const $CopyWithPlaceholder()
          ? _value.faceMatch
          // ignore: cast_nullable_to_non_nullable
          : faceMatch as VerificationReviewFaceMatchEnum?,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ReviewItem>,
    );
  }
}

extension $VerificationReviewCopyWith on VerificationReview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVerificationReview.copyWith(...)` or `instanceOfVerificationReview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VerificationReviewCWProxy get copyWith =>
      _$VerificationReviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationReview _$VerificationReviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VerificationReview', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['providerId', 'level', 'profile', 'items'],
      );
      final val = VerificationReview(
        providerId: $checkedConvert('providerId', (v) => v as String),
        level: $checkedConvert('level', (v) => (v as num).toInt()),
        profile: $checkedConvert(
          'profile',
          (v) => VerificationReviewProfile.fromJson(v as Map<String, dynamic>),
        ),
        faceMatch: $checkedConvert(
          'faceMatch',
          (v) =>
              $enumDecodeNullable(_$VerificationReviewFaceMatchEnumEnumMap, v),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$VerificationReviewToJson(
  VerificationReview instance,
) => <String, dynamic>{
  'providerId': instance.providerId,
  'level': instance.level,
  'profile': instance.profile.toJson(),
  'faceMatch': ?_$VerificationReviewFaceMatchEnumEnumMap[instance.faceMatch],
  'items': instance.items.map((e) => e.toJson()).toList(),
};

const _$VerificationReviewFaceMatchEnumEnumMap = {
  VerificationReviewFaceMatchEnum.notRun: 'not_run',
  VerificationReviewFaceMatchEnum.match: 'match',
  VerificationReviewFaceMatchEnum.noMatch: 'no_match',
  VerificationReviewFaceMatchEnum.manualReview: 'manual_review',
};
