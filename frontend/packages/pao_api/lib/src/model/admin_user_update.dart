//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/admin_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_user_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserUpdate {
  /// Returns a new [AdminUserUpdate] instance.
  AdminUserUpdate({this.roles, this.active});

  @JsonKey(name: r'roles', required: false, includeIfNull: false)
  final List<AdminRole>? roles;

  @JsonKey(name: r'active', required: false, includeIfNull: false)
  final bool? active;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminUserUpdate &&
            runtimeType == other.runtimeType &&
            equals([roles, active], [other.roles, other.active]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([roles, active]);

  factory AdminUserUpdate.fromJson(Map<String, dynamic> json) =>
      _$AdminUserUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
