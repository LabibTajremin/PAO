//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/point.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'heartbeat_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HeartbeatInput {
  /// Returns a new [HeartbeatInput] instance.
  HeartbeatInput({required this.location});

  @JsonKey(name: r'location', required: true, includeIfNull: false)
  final Point location;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HeartbeatInput &&
            runtimeType == other.runtimeType &&
            equals([location], [other.location]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([location]);

  factory HeartbeatInput.fromJson(Map<String, dynamic> json) =>
      _$HeartbeatInputFromJson(json);

  Map<String, dynamic> toJson() => _$HeartbeatInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
