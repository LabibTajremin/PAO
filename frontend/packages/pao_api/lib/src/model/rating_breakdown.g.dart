// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_breakdown.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RatingBreakdownCWProxy {
  RatingBreakdown average(double average);

  RatingBreakdown count(int count);

  RatingBreakdown distribution(Map<String, int> distribution);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RatingBreakdown(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RatingBreakdown(...).copyWith(id: 12, name: "My name")
  /// ```
  RatingBreakdown call({
    double average,
    int count,
    Map<String, int> distribution,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRatingBreakdown.copyWith(...)` or call `instanceOfRatingBreakdown.copyWith.fieldName(value)` for a single field.
class _$RatingBreakdownCWProxyImpl implements _$RatingBreakdownCWProxy {
  const _$RatingBreakdownCWProxyImpl(this._value);

  final RatingBreakdown _value;

  @override
  RatingBreakdown average(double average) => call(average: average);

  @override
  RatingBreakdown count(int count) => call(count: count);

  @override
  RatingBreakdown distribution(Map<String, int> distribution) =>
      call(distribution: distribution);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RatingBreakdown(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RatingBreakdown(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RatingBreakdown call({
    Object? average = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? distribution = const $CopyWithPlaceholder(),
  }) {
    return RatingBreakdown(
      average: average == const $CopyWithPlaceholder() || average == null
          ? _value.average
          // ignore: cast_nullable_to_non_nullable
          : average as double,
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      distribution:
          distribution == const $CopyWithPlaceholder() || distribution == null
          ? _value.distribution
          // ignore: cast_nullable_to_non_nullable
          : distribution as Map<String, int>,
    );
  }
}

extension $RatingBreakdownCopyWith on RatingBreakdown {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRatingBreakdown.copyWith(...)` or `instanceOfRatingBreakdown.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RatingBreakdownCWProxy get copyWith => _$RatingBreakdownCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingBreakdown _$RatingBreakdownFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RatingBreakdown', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['average', 'count', 'distribution'],
      );
      final val = RatingBreakdown(
        average: $checkedConvert('average', (v) => (v as num).toDouble()),
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        distribution: $checkedConvert(
          'distribution',
          (v) => Map<String, int>.from(v as Map),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RatingBreakdownToJson(RatingBreakdown instance) =>
    <String, dynamic>{
      'average': instance.average,
      'count': instance.count,
      'distribution': instance.distribution,
    };
