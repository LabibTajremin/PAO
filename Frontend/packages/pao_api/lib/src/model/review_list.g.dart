// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewListCWProxy {
  ReviewList items(List<Review> items);

  ReviewList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewList(...).copyWith(id: 12, name: "My name")
  /// ```
  ReviewList call({List<Review> items, String? nextCursor});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReviewList.copyWith(...)` or call `instanceOfReviewList.copyWith.fieldName(value)` for a single field.
class _$ReviewListCWProxyImpl implements _$ReviewListCWProxy {
  const _$ReviewListCWProxyImpl(this._value);

  final ReviewList _value;

  @override
  ReviewList items(List<Review> items) => call(items: items);

  @override
  ReviewList nextCursor(String? nextCursor) => call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReviewList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return ReviewList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Review>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $ReviewListCopyWith on ReviewList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReviewList.copyWith(...)` or `instanceOfReviewList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewListCWProxy get copyWith => _$ReviewListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewList _$ReviewListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ReviewList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ReviewListToJson(ReviewList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
