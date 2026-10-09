//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'refresh_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RefreshRequest {
  /// Returns a new [RefreshRequest] instance.
  RefreshRequest({this.refreshToken});

  @JsonKey(name: r'refreshToken', required: false, includeIfNull: false)
  final String? refreshToken;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RefreshRequest &&
            runtimeType == other.runtimeType &&
            equals([refreshToken], [other.refreshToken]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([refreshToken]);

  factory RefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
