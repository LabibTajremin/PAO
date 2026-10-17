//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_status.dart';
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/timing.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'booking_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BookingSummary {
  /// Returns a new [BookingSummary] instance.
  BookingSummary({
    required this.id,

    required this.number,

    required this.status,

    required this.serviceName,

    this.counterpartName,

    this.timing,

    this.scheduledAt,

    required this.total,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'number', required: true, includeIfNull: false)
  final String number;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final BookingStatus status;

  @JsonKey(name: r'serviceName', required: true, includeIfNull: false)
  final LocalizedText serviceName;

  @JsonKey(name: r'counterpartName', required: false, includeIfNull: false)
  final String? counterpartName;

  @JsonKey(name: r'timing', required: false, includeIfNull: false)
  final Timing? timing;

  @JsonKey(name: r'scheduledAt', required: false, includeIfNull: false)
  final DateTime? scheduledAt;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BookingSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                number,
                status,
                serviceName,
                counterpartName,
                timing,
                scheduledAt,
                total,
                createdAt,
              ],
              [
                other.id,
                other.number,
                other.status,
                other.serviceName,
                other.counterpartName,
                other.timing,
                other.scheduledAt,
                other.total,
                other.createdAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        number,
        status,
        serviceName,
        counterpartName,
        timing,
        scheduledAt,
        total,
        createdAt,
      ]);

  factory BookingSummary.fromJson(Map<String, dynamic> json) =>
      _$BookingSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$BookingSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
