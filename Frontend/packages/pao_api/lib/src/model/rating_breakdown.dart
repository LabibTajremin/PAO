//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'rating_breakdown.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RatingBreakdown {
  /// Returns a new [RatingBreakdown] instance.
  RatingBreakdown({
    required this.average,

    required this.count,

    required this.distribution,
  });

  @JsonKey(name: r'average', required: true, includeIfNull: false)
  final double average;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  /// Count of reviews per star value \"1\"..\"5\".
  @JsonKey(name: r'distribution', required: true, includeIfNull: false)
  final Map<String, int> distribution;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RatingBreakdown &&
            runtimeType == other.runtimeType &&
            equals(
              [average, count, distribution],
              [other.average, other.count, other.distribution],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([average, count, distribution]);

  factory RatingBreakdown.fromJson(Map<String, dynamic> json) =>
      _$RatingBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$RatingBreakdownToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
