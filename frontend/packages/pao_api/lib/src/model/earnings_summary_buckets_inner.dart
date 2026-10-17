//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'earnings_summary_buckets_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EarningsSummaryBucketsInner {
  /// Returns a new [EarningsSummaryBucketsInner] instance.
  EarningsSummaryBucketsInner({
    required this.date,

    required this.total,

    required this.jobs,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final String date;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'jobs', required: true, includeIfNull: false)
  final int jobs;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EarningsSummaryBucketsInner &&
            runtimeType == other.runtimeType &&
            equals([date, total, jobs], [other.date, other.total, other.jobs]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([date, total, jobs]);

  factory EarningsSummaryBucketsInner.fromJson(Map<String, dynamic> json) =>
      _$EarningsSummaryBucketsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$EarningsSummaryBucketsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
