//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'my_permissions.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MyPermissions {
  /// Returns a new [MyPermissions] instance.
  MyPermissions({
    required this.roles,

    required this.permissions,

    required this.screens,

    this.providerGate,
  });

  @JsonKey(name: r'roles', required: true, includeIfNull: false)
  final List<Role> roles;

  @JsonKey(name: r'permissions', required: true, includeIfNull: false)
  final List<String> permissions;

  @JsonKey(name: r'screens', required: true, includeIfNull: false)
  final List<String> screens;

  /// True while a provider is below Level 1 and limited to screens M01–M14.
  @JsonKey(name: r'providerGate', required: false, includeIfNull: false)
  final bool? providerGate;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MyPermissions &&
            runtimeType == other.runtimeType &&
            equals(
              [roles, permissions, screens, providerGate],
              [
                other.roles,
                other.permissions,
                other.screens,
                other.providerGate,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([roles, permissions, screens, providerGate]);

  factory MyPermissions.fromJson(Map<String, dynamic> json) =>
      _$MyPermissionsFromJson(json);

  Map<String, dynamic> toJson() => _$MyPermissionsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
