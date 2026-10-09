// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewInputCWProxy {
  ReviewInput stars(int stars);

  ReviewInput tags(Set<ReviewTag>? tags);

  ReviewInput comment(String? comment);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ReviewInput call({int stars, Set<ReviewTag>? tags, String? comment});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReviewInput.copyWith(...)` or call `instanceOfReviewInput.copyWith.fieldName(value)` for a single field.
class _$ReviewInputCWProxyImpl implements _$ReviewInputCWProxy {
  const _$ReviewInputCWProxyImpl(this._value);

  final ReviewInput _value;

  @override
  ReviewInput stars(int stars) => call(stars: stars);

  @override
  ReviewInput tags(Set<ReviewTag>? tags) => call(tags: tags);

  @override
  ReviewInput comment(String? comment) => call(comment: comment);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReviewInput call({
    Object? stars = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? comment = const $CopyWithPlaceholder(),
  }) {
    return ReviewInput(
      stars: stars == const $CopyWithPlaceholder() || stars == null
          ? _value.stars
          // ignore: cast_nullable_to_non_nullable
          : stars as int,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as Set<ReviewTag>?,
      comment: comment == const $CopyWithPlaceholder()
          ? _value.comment
          // ignore: cast_nullable_to_non_nullable
          : comment as String?,
    );
  }
}

extension $ReviewInputCopyWith on ReviewInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReviewInput.copyWith(...)` or `instanceOfReviewInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewInputCWProxy get copyWith => _$ReviewInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewInput _$ReviewInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['stars']);
      final val = ReviewInput(
        stars: $checkedConvert('stars', (v) => (v as num).toInt()),
        tags: $checkedConvert(
          'tags',
          (v) => (v as List<dynamic>?)
              ?.map((e) => $enumDecode(_$ReviewTagEnumMap, e))
              .toSet(),
        ),
        comment: $checkedConvert('comment', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ReviewInputToJson(ReviewInput instance) =>
    <String, dynamic>{
      'stars': instance.stars,
      'tags': ?instance.tags?.map((e) => _$ReviewTagEnumMap[e]!).toList(),
      'comment': ?instance.comment,
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
