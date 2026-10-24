// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewCWProxy {
  Review id(String id);

  Review bookingId(String bookingId);

  Review stars(int stars);

  Review tags(List<ReviewTag> tags);

  Review comment(String? comment);

  Review authorName(String authorName);

  Review serviceName(LocalizedText? serviceName);

  Review createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Review(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Review(...).copyWith(id: 12, name: "My name")
  /// ```
  Review call({
    String id,
    String bookingId,
    int stars,
    List<ReviewTag> tags,
    String? comment,
    String authorName,
    LocalizedText? serviceName,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReview.copyWith(...)` or call `instanceOfReview.copyWith.fieldName(value)` for a single field.
class _$ReviewCWProxyImpl implements _$ReviewCWProxy {
  const _$ReviewCWProxyImpl(this._value);

  final Review _value;

  @override
  Review id(String id) => call(id: id);

  @override
  Review bookingId(String bookingId) => call(bookingId: bookingId);

  @override
  Review stars(int stars) => call(stars: stars);

  @override
  Review tags(List<ReviewTag> tags) => call(tags: tags);

  @override
  Review comment(String? comment) => call(comment: comment);

  @override
  Review authorName(String authorName) => call(authorName: authorName);

  @override
  Review serviceName(LocalizedText? serviceName) =>
      call(serviceName: serviceName);

  @override
  Review createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Review(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Review(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Review call({
    Object? id = const $CopyWithPlaceholder(),
    Object? bookingId = const $CopyWithPlaceholder(),
    Object? stars = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? comment = const $CopyWithPlaceholder(),
    Object? authorName = const $CopyWithPlaceholder(),
    Object? serviceName = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Review(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      bookingId: bookingId == const $CopyWithPlaceholder() || bookingId == null
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String,
      stars: stars == const $CopyWithPlaceholder() || stars == null
          ? _value.stars
          // ignore: cast_nullable_to_non_nullable
          : stars as int,
      tags: tags == const $CopyWithPlaceholder() || tags == null
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<ReviewTag>,
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
      authorName:
          authorName == const $CopyWithPlaceholder() || authorName == null
          ? _value.authorName
          // ignore: cast_nullable_to_non_nullable
          : authorName as String,
      serviceName: serviceName == const $CopyWithPlaceholder()
          ? _value.serviceName
          // ignore: cast_nullable_to_non_nullable
          : serviceName as LocalizedText?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ReviewCopyWith on Review {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReview.copyWith(...)` or `instanceOfReview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewCWProxy get copyWith => _$ReviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Review', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'bookingId',
      'stars',
      'tags',
      'authorName',
      'createdAt',
    ],
  );
  final val = Review(
    id: $checkedConvert('id', (v) => v as String),
    bookingId: $checkedConvert('bookingId', (v) => v as String),
    stars: $checkedConvert('stars', (v) => (v as num).toInt()),
    tags: $checkedConvert(
      'tags',
      (v) => (v as List<dynamic>)
          .map((e) => $enumDecode(_$ReviewTagEnumMap, e))
          .toList(),
    ),
    comment: $checkedConvert('comment', (v) => v as String?),
    authorName: $checkedConvert('authorName', (v) => v as String),
    serviceName: $checkedConvert(
      'serviceName',
      (v) =>
          v == null ? null : LocalizedText.fromJson(v as Map<String, dynamic>),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': instance.id,
  'bookingId': instance.bookingId,
  'stars': instance.stars,
  'tags': instance.tags.map((e) => _$ReviewTagEnumMap[e]!).toList(),
  'comment': ?instance.comment,
  'authorName': instance.authorName,
  'serviceName': ?instance.serviceName?.toJson(),
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$ReviewTagEnumMap = {
  ReviewTag.onTime: 'on_time',
  ReviewTag.professional: 'professional',
  ReviewTag.qualityWork: 'quality_work',
  ReviewTag.clean: 'clean',
  ReviewTag.friendly: 'friendly',
  ReviewTag.fairPrice: 'fair_price',
  ReviewTag.late_: 'late',
  ReviewTag.rude: 'rude',
  ReviewTag.poorQuality: 'poor_quality',
  ReviewTag.messy: 'messy',
  ReviewTag.polite: 'polite',
  ReviewTag.clearInstructions: 'clear_instructions',
  ReviewTag.paidPromptly: 'paid_promptly',
  ReviewTag.safePlace: 'safe_place',
  ReviewTag.unclearInstructions: 'unclear_instructions',
  ReviewTag.unsafePlace: 'unsafe_place',
};
