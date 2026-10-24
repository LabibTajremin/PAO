//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/platform.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'device_token_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceTokenInput {
  /// Returns a new [DeviceTokenInput] instance.
  DeviceTokenInput({required this.token, required this.platform});

  @JsonKey(name: r'token', required: true, includeIfNull: false)
  final String token;

  @JsonKey(name: r'platform', required: true, includeIfNull: false)
  final Platform platform;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeviceTokenInput &&
            runtimeType == other.runtimeType &&
            equals([token, platform], [other.token, other.platform]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([token, platform]);

  factory DeviceTokenInput.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenInputFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceTokenInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
