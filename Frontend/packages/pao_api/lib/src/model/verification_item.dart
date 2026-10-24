//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/item_status.dart';
import 'package:pao_api/src/model/item_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'verification_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerificationItem {
  /// Returns a new [VerificationItem] instance.
  VerificationItem({
    required this.type,

    required this.status,

    required this.required_,

    this.rejectionReason,

    this.expiresAt,

    this.decidedAt,
  });

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final ItemType type;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ItemStatus status;

  @JsonKey(name: r'required', required: true, includeIfNull: false)
  final bool required_;

  @JsonKey(name: r'rejectionReason', required: false, includeIfNull: false)
  final String? rejectionReason;

  @JsonKey(name: r'expiresAt', required: false, includeIfNull: false)
  final DateTime? expiresAt;

  @JsonKey(name: r'decidedAt', required: false, includeIfNull: false)
  final DateTime? decidedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VerificationItem &&
            runtimeType == other.runtimeType &&
            equals(
              [type, status, required_, rejectionReason, expiresAt, decidedAt],
              [
                other.type,
                other.status,
                other.required_,
                other.rejectionReason,
                other.expiresAt,
                other.decidedAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        type,
        status,
        required_,
        rejectionReason,
        expiresAt,
        decidedAt,
      ]);

  factory VerificationItem.fromJson(Map<String, dynamic> json) =>
      _$VerificationItemFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
