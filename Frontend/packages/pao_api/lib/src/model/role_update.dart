//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'role_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RoleUpdate {
  /// Returns a new [RoleUpdate] instance.
  RoleUpdate({required this.permissions, required this.screens});

  @JsonKey(name: r'permissions', required: true, includeIfNull: false)
  final List<String> permissions;

  @JsonKey(name: r'screens', required: true, includeIfNull: false)
  final List<String> screens;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RoleUpdate &&
            runtimeType == other.runtimeType &&
            equals([permissions, screens], [other.permissions, other.screens]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([permissions, screens]);

  factory RoleUpdate.fromJson(Map<String, dynamic> json) =>
      _$RoleUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$RoleUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
