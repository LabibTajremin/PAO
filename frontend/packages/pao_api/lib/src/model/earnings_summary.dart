//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/earnings_period.dart';
import 'package:pao_api/src/model/earnings_summary_buckets_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'earnings_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EarningsSummary {
  /// Returns a new [EarningsSummary] instance.
  EarningsSummary({
    required this.period,

    required this.from,

    required this.to,

    required this.total,

    required this.jobs,

    required this.buckets,
  });

  @JsonKey(name: r'period', required: true, includeIfNull: false)
  final EarningsPeriod period;

  @JsonKey(name: r'from', required: true, includeIfNull: false)
  final DateTime from;

  @JsonKey(name: r'to', required: true, includeIfNull: false)
  final DateTime to;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'jobs', required: true, includeIfNull: false)
  final int jobs;

  @JsonKey(name: r'buckets', required: true, includeIfNull: false)
  final List<EarningsSummaryBucketsInner> buckets;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EarningsSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [period, from, to, total, jobs, buckets],
              [
                other.period,
                other.from,
                other.to,
                other.total,
                other.jobs,
                other.buckets,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([period, from, to, total, jobs, buckets]);

  factory EarningsSummary.fromJson(Map<String, dynamic> json) =>
      _$EarningsSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$EarningsSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
