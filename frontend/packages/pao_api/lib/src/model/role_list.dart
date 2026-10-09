//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/role_definition.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'role_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RoleList {
  /// Returns a new [RoleList] instance.
  RoleList({
    required this.items,

    required this.allPermissions,

    required this.allScreens,
  });

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<RoleDefinition> items;

  @JsonKey(name: r'allPermissions', required: true, includeIfNull: false)
  final List<String> allPermissions;

  @JsonKey(name: r'allScreens', required: true, includeIfNull: false)
  final List<String> allScreens;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RoleList &&
            runtimeType == other.runtimeType &&
            equals(
              [items, allPermissions, allScreens],
              [other.items, other.allPermissions, other.allScreens],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([items, allPermissions, allScreens]);

  factory RoleList.fromJson(Map<String, dynamic> json) =>
      _$RoleListFromJson(json);

  Map<String, dynamic> toJson() => _$RoleListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
