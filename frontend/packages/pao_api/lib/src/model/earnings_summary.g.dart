// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EarningsSummaryCWProxy {
  EarningsSummary period(EarningsPeriod period);

  EarningsSummary from(DateTime from);

  EarningsSummary to(DateTime to);

  EarningsSummary total(int total);

  EarningsSummary jobs(int jobs);

  EarningsSummary buckets(List<EarningsSummaryBucketsInner> buckets);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EarningsSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EarningsSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  EarningsSummary call({
    EarningsPeriod period,
    DateTime from,
    DateTime to,
    int total,
    int jobs,
    List<EarningsSummaryBucketsInner> buckets,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEarningsSummary.copyWith(...)` or call `instanceOfEarningsSummary.copyWith.fieldName(value)` for a single field.
class _$EarningsSummaryCWProxyImpl implements _$EarningsSummaryCWProxy {
  const _$EarningsSummaryCWProxyImpl(this._value);

  final EarningsSummary _value;

  @override
  EarningsSummary period(EarningsPeriod period) => call(period: period);

  @override
  EarningsSummary from(DateTime from) => call(from: from);

  @override
  EarningsSummary to(DateTime to) => call(to: to);

  @override
  EarningsSummary total(int total) => call(total: total);

  @override
  EarningsSummary jobs(int jobs) => call(jobs: jobs);

  @override
  EarningsSummary buckets(List<EarningsSummaryBucketsInner> buckets) =>
      call(buckets: buckets);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EarningsSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EarningsSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EarningsSummary call({
    Object? period = const $CopyWithPlaceholder(),
    Object? from = const $CopyWithPlaceholder(),
    Object? to = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? jobs = const $CopyWithPlaceholder(),
    Object? buckets = const $CopyWithPlaceholder(),
  }) {
    return EarningsSummary(
      period: period == const $CopyWithPlaceholder() || period == null
          ? _value.period
          // ignore: cast_nullable_to_non_nullable
          : period as EarningsPeriod,
      from: from == const $CopyWithPlaceholder() || from == null
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as DateTime,
      to: to == const $CopyWithPlaceholder() || to == null
          ? _value.to
          // ignore: cast_nullable_to_non_nullable
          : to as DateTime,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      jobs: jobs == const $CopyWithPlaceholder() || jobs == null
          ? _value.jobs
          // ignore: cast_nullable_to_non_nullable
          : jobs as int,
      buckets: buckets == const $CopyWithPlaceholder() || buckets == null
          ? _value.buckets
          // ignore: cast_nullable_to_non_nullable
          : buckets as List<EarningsSummaryBucketsInner>,
    );
  }
}

extension $EarningsSummaryCopyWith on EarningsSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEarningsSummary.copyWith(...)` or `instanceOfEarningsSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EarningsSummaryCWProxy get copyWith => _$EarningsSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EarningsSummary _$EarningsSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EarningsSummary', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['period', 'from', 'to', 'total', 'jobs', 'buckets'],
  );
  final val = EarningsSummary(
    period: $checkedConvert(
      'period',
      (v) => $enumDecode(_$EarningsPeriodEnumMap, v),
    ),
    from: $checkedConvert('from', (v) => DateTime.parse(v as String)),
    to: $checkedConvert('to', (v) => DateTime.parse(v as String)),
    total: $checkedConvert('total', (v) => (v as num).toInt()),
    jobs: $checkedConvert('jobs', (v) => (v as num).toInt()),
    buckets: $checkedConvert(
      'buckets',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                EarningsSummaryBucketsInner.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$EarningsSummaryToJson(EarningsSummary instance) =>
    <String, dynamic>{
      'period': _$EarningsPeriodEnumMap[instance.period]!,
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'total': instance.total,
      'jobs': instance.jobs,
      'buckets': instance.buckets.map((e) => e.toJson()).toList(),
    };

const _$EarningsPeriodEnumMap = {
  EarningsPeriod.day: 'day',
  EarningsPeriod.week: 'week',
  EarningsPeriod.month: 'month',
};
