//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/admin_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_user_invite.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserInvite {
  /// Returns a new [AdminUserInvite] instance.
  AdminUserInvite({
    required this.email,

    required this.name,

    required this.roles,
  });

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'roles', required: true, includeIfNull: false)
  final List<AdminRole> roles;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminUserInvite &&
            runtimeType == other.runtimeType &&
            equals(
              [email, name, roles],
              [other.email, other.name, other.roles],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([email, name, roles]);

  factory AdminUserInvite.fromJson(Map<String, dynamic> json) =>
      _$AdminUserInviteFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserInviteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
