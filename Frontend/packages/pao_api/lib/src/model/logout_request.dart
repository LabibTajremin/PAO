//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'logout_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LogoutRequest {
  /// Returns a new [LogoutRequest] instance.
  LogoutRequest({this.allDevices = false});

  @JsonKey(
    defaultValue: false,
    name: r'allDevices',
    required: false,
    includeIfNull: false,
  )
  final bool? allDevices;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LogoutRequest &&
            runtimeType == other.runtimeType &&
            equals([allDevices], [other.allDevices]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([allDevices]);

  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      _$LogoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
