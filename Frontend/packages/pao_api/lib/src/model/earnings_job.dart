//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'earnings_job.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EarningsJob {
  /// Returns a new [EarningsJob] instance.
  EarningsJob({
    required this.bookingId,

    required this.number,

    required this.completedAt,

    required this.serviceName,

    required this.total,
  });

  @JsonKey(name: r'bookingId', required: true, includeIfNull: false)
  final String bookingId;

  @JsonKey(name: r'number', required: true, includeIfNull: false)
  final String number;

  @JsonKey(name: r'completedAt', required: true, includeIfNull: false)
  final DateTime completedAt;

  @JsonKey(name: r'serviceName', required: true, includeIfNull: false)
  final LocalizedText serviceName;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EarningsJob &&
            runtimeType == other.runtimeType &&
            equals(
              [bookingId, number, completedAt, serviceName, total],
              [
                other.bookingId,
                other.number,
                other.completedAt,
                other.serviceName,
                other.total,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([bookingId, number, completedAt, serviceName, total]);

  factory EarningsJob.fromJson(Map<String, dynamic> json) =>
      _$EarningsJobFromJson(json);

  Map<String, dynamic> toJson() => _$EarningsJobToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
