//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/admin_user.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_user_invited.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUserInvited {
  /// Returns a new [AdminUserInvited] instance.
  AdminUserInvited({required this.user, required this.temporaryPassword});

  @JsonKey(name: r'user', required: true, includeIfNull: false)
  final AdminUser user;

  /// Shown once; the admin must change it and enrol TOTP on first login.
  @JsonKey(name: r'temporaryPassword', required: true, includeIfNull: false)
  final String temporaryPassword;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminUserInvited &&
            runtimeType == other.runtimeType &&
            equals(
              [user, temporaryPassword],
              [other.user, other.temporaryPassword],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([user, temporaryPassword]);

  factory AdminUserInvited.fromJson(Map<String, dynamic> json) =>
      _$AdminUserInvitedFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserInvitedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
