//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'role_definition.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RoleDefinition {
  /// Returns a new [RoleDefinition] instance.
  RoleDefinition({
    required this.role,

    required this.permissions,

    required this.screens,
  });

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final Role role;

  @JsonKey(name: r'permissions', required: true, includeIfNull: false)
  final List<String> permissions;

  @JsonKey(name: r'screens', required: true, includeIfNull: false)
  final List<String> screens;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RoleDefinition &&
            runtimeType == other.runtimeType &&
            equals(
              [role, permissions, screens],
              [other.role, other.permissions, other.screens],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([role, permissions, screens]);

  factory RoleDefinition.fromJson(Map<String, dynamic> json) =>
      _$RoleDefinitionFromJson(json);

  Map<String, dynamic> toJson() => _$RoleDefinitionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
