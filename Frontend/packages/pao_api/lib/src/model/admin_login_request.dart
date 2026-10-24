//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_login_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminLoginRequest {
  /// Returns a new [AdminLoginRequest] instance.
  AdminLoginRequest({required this.email, required this.password});

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'password', required: true, includeIfNull: false)
  final String password;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminLoginRequest &&
            runtimeType == other.runtimeType &&
            equals([email, password], [other.email, other.password]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([email, password]);

  factory AdminLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminLoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminLoginRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
