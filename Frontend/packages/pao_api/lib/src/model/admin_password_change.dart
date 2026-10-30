//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_password_change.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPasswordChange {
  /// Returns a new [AdminPasswordChange] instance.
  AdminPasswordChange({
    required this.currentPassword,

    required this.newPassword,
  });

  @JsonKey(name: r'currentPassword', required: true, includeIfNull: false)
  final String currentPassword;

  @JsonKey(name: r'newPassword', required: true, includeIfNull: false)
  final String newPassword;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminPasswordChange &&
            runtimeType == other.runtimeType &&
            equals(
              [currentPassword, newPassword],
              [other.currentPassword, other.newPassword],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([currentPassword, newPassword]);

  factory AdminPasswordChange.fromJson(Map<String, dynamic> json) =>
      _$AdminPasswordChangeFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPasswordChangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
