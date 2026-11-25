//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/delivery_pattern.dart';
import 'package:pao_api/src/model/quantity_unit.dart';
import 'package:pao_api/src/model/delivery_window.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'service_schedule.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServiceSchedule {
  /// Returns a new [ServiceSchedule] instance.
  ServiceSchedule({
    required this.patterns,

    required this.windows,

    required this.leadHours,

    required this.cutoff,

    required this.unit,

    required this.minQuantity,

    required this.maxQuantity,
  });

  @JsonKey(name: r'patterns', required: true, includeIfNull: false)
  final Set<DeliveryPattern> patterns;

  @JsonKey(name: r'windows', required: true, includeIfNull: false)
  final List<DeliveryWindow> windows;

  // minimum: 0
  // maximum: 336
  @JsonKey(name: r'leadHours', required: true, includeIfNull: false)
  final int leadHours;

  /// Orders and changes for a date close at this time on the day before.
  @JsonKey(name: r'cutoff', required: true, includeIfNull: false)
  final String cutoff;

  @JsonKey(name: r'unit', required: true, includeIfNull: false)
  final QuantityUnit unit;

  // minimum: 1
  // maximum: 500
  @JsonKey(name: r'minQuantity', required: true, includeIfNull: false)
  final int minQuantity;

  // minimum: 1
  // maximum: 500
  @JsonKey(name: r'maxQuantity', required: true, includeIfNull: false)
  final int maxQuantity;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceSchedule &&
            runtimeType == other.runtimeType &&
            equals(
              [
                patterns,
                windows,
                leadHours,
                cutoff,
                unit,
                minQuantity,
                maxQuantity,
              ],
              [
                other.patterns,
                other.windows,
                other.leadHours,
                other.cutoff,
                other.unit,
                other.minQuantity,
                other.maxQuantity,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        patterns,
        windows,
        leadHours,
        cutoff,
        unit,
        minQuantity,
        maxQuantity,
      ]);

  factory ServiceSchedule.fromJson(Map<String, dynamic> json) =>
      _$ServiceScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceScheduleToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
