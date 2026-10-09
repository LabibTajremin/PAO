//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/account_status.dart';
import 'package:pao_api/src/model/role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'account.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Account {
  /// Returns a new [Account] instance.
  Account({
    required this.id,

    this.phone,

    this.email,

    required this.roles,

    required this.status,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'email', required: false, includeIfNull: false)
  final String? email;

  @JsonKey(name: r'roles', required: true, includeIfNull: false)
  final List<Role> roles;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AccountStatus status;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Account &&
            runtimeType == other.runtimeType &&
            equals(
              [id, phone, email, roles, status, createdAt],
              [
                other.id,
                other.phone,
                other.email,
                other.roles,
                other.status,
                other.createdAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, phone, email, roles, status, createdAt]);

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
