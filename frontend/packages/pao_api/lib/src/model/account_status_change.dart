//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'account_status_change.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccountStatusChange {
  /// Returns a new [AccountStatusChange] instance.
  AccountStatusChange({required this.status, required this.reason});

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AccountStatusChangeStatusEnum status;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountStatusChange &&
            runtimeType == other.runtimeType &&
            equals([status, reason], [other.status, other.reason]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([status, reason]);

  factory AccountStatusChange.fromJson(Map<String, dynamic> json) =>
      _$AccountStatusChangeFromJson(json);

  Map<String, dynamic> toJson() => _$AccountStatusChangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AccountStatusChangeStatusEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'suspended')
  suspended(r'suspended'),
  @JsonValue(r'banned')
  banned(r'banned');

  const AccountStatusChangeStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
