//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'presence_state.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PresenceState {
  /// Returns a new [PresenceState] instance.
  PresenceState({required this.online, this.heartbeatIntervalSeconds});

  @JsonKey(name: r'online', required: true, includeIfNull: false)
  final bool online;

  @JsonKey(
    name: r'heartbeatIntervalSeconds',
    required: false,
    includeIfNull: false,
  )
  final int? heartbeatIntervalSeconds;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PresenceState &&
            runtimeType == other.runtimeType &&
            equals(
              [online, heartbeatIntervalSeconds],
              [other.online, other.heartbeatIntervalSeconds],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([online, heartbeatIntervalSeconds]);

  factory PresenceState.fromJson(Map<String, dynamic> json) =>
      _$PresenceStateFromJson(json);

  Map<String, dynamic> toJson() => _$PresenceStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
