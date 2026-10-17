//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'level2_session_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Level2SessionInput {
  /// Returns a new [Level2SessionInput] instance.
  Level2SessionInput({
    required this.providerId,

    required this.serviceId,

    required this.scheduledAt,

    required this.location,
  });

  @JsonKey(name: r'providerId', required: true, includeIfNull: false)
  final String providerId;

  @JsonKey(name: r'serviceId', required: true, includeIfNull: false)
  final String serviceId;

  @JsonKey(name: r'scheduledAt', required: true, includeIfNull: false)
  final DateTime scheduledAt;

  @JsonKey(name: r'location', required: true, includeIfNull: false)
  final String location;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Level2SessionInput &&
            runtimeType == other.runtimeType &&
            equals(
              [providerId, serviceId, scheduledAt, location],
              [
                other.providerId,
                other.serviceId,
                other.scheduledAt,
                other.location,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([providerId, serviceId, scheduledAt, location]);

  factory Level2SessionInput.fromJson(Map<String, dynamic> json) =>
      _$Level2SessionInputFromJson(json);

  Map<String, dynamic> toJson() => _$Level2SessionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
