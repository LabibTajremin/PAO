//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/admin_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_user.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUser {
  /// Returns a new [AdminUser] instance.
  AdminUser({
    required this.id,

    required this.email,

    required this.name,

    required this.roles,

    required this.active,

    required this.totpEnrolled,

    this.lastLoginAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'roles', required: true, includeIfNull: false)
  final List<AdminRole> roles;

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @JsonKey(name: r'totpEnrolled', required: true, includeIfNull: false)
  final bool totpEnrolled;

  @JsonKey(name: r'lastLoginAt', required: false, includeIfNull: false)
  final DateTime? lastLoginAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminUser &&
            runtimeType == other.runtimeType &&
            equals(
              [id, email, name, roles, active, totpEnrolled, lastLoginAt],
              [
                other.id,
                other.email,
                other.name,
                other.roles,
                other.active,
                other.totpEnrolled,
                other.lastLoginAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        email,
        name,
        roles,
        active,
        totpEnrolled,
        lastLoginAt,
      ]);

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
