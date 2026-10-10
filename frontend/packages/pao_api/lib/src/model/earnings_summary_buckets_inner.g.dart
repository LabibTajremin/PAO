// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_summary_buckets_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EarningsSummaryBucketsInnerCWProxy {
  EarningsSummaryBucketsInner date(String date);

  EarningsSummaryBucketsInner total(int total);

  EarningsSummaryBucketsInner jobs(int jobs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EarningsSummaryBucketsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EarningsSummaryBucketsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  EarningsSummaryBucketsInner call({String date, int total, int jobs});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEarningsSummaryBucketsInner.copyWith(...)` or call `instanceOfEarningsSummaryBucketsInner.copyWith.fieldName(value)` for a single field.
class _$EarningsSummaryBucketsInnerCWProxyImpl
    implements _$EarningsSummaryBucketsInnerCWProxy {
  const _$EarningsSummaryBucketsInnerCWProxyImpl(this._value);

  final EarningsSummaryBucketsInner _value;

  @override
  EarningsSummaryBucketsInner date(String date) => call(date: date);

  @override
  EarningsSummaryBucketsInner total(int total) => call(total: total);

  @override
  EarningsSummaryBucketsInner jobs(int jobs) => call(jobs: jobs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EarningsSummaryBucketsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EarningsSummaryBucketsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EarningsSummaryBucketsInner call({
    Object? date = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? jobs = const $CopyWithPlaceholder(),
  }) {
    return EarningsSummaryBucketsInner(
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      jobs: jobs == const $CopyWithPlaceholder() || jobs == null
          ? _value.jobs
          // ignore: cast_nullable_to_non_nullable
          : jobs as int,
    );
  }
}

extension $EarningsSummaryBucketsInnerCopyWith on EarningsSummaryBucketsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEarningsSummaryBucketsInner.copyWith(...)` or `instanceOfEarningsSummaryBucketsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EarningsSummaryBucketsInnerCWProxy get copyWith =>
      _$EarningsSummaryBucketsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EarningsSummaryBucketsInner _$EarningsSummaryBucketsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EarningsSummaryBucketsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['date', 'total', 'jobs']);
  final val = EarningsSummaryBucketsInner(
    date: $checkedConvert('date', (v) => v as String),
    total: $checkedConvert('total', (v) => (v as num).toInt()),
    jobs: $checkedConvert('jobs', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$EarningsSummaryBucketsInnerToJson(
  EarningsSummaryBucketsInner instance,
) => <String, dynamic>{
  'date': instance.date,
  'total': instance.total,
  'jobs': instance.jobs,
};
