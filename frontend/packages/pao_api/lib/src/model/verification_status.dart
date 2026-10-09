//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/badge.dart';
import 'package:pao_api/src/model/verification_item.dart';
import 'package:pao_api/src/model/level2_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'verification_status.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerificationStatus {
  /// Returns a new [VerificationStatus] instance.
  VerificationStatus({
    required this.level,

    required this.badge,

    required this.items,

    required this.canReceiveBookings,

    this.level2,
  });

  /// Verification level (PRD §6.1) — 0 Registered, 1 Verified, 2 PAO Verified Pro.
  // minimum: 0
  // maximum: 2
  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final int level;

  @JsonKey(name: r'badge', required: true, includeIfNull: false)
  final Badge badge;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<VerificationItem> items;

  @JsonKey(name: r'canReceiveBookings', required: true, includeIfNull: false)
  final bool canReceiveBookings;

  @JsonKey(name: r'level2', required: false, includeIfNull: false)
  final Level2Info? level2;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VerificationStatus &&
            runtimeType == other.runtimeType &&
            equals(
              [level, badge, items, canReceiveBookings, level2],
              [
                other.level,
                other.badge,
                other.items,
                other.canReceiveBookings,
                other.level2,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([level, badge, items, canReceiveBookings, level2]);

  factory VerificationStatus.fromJson(Map<String, dynamic> json) =>
      _$VerificationStatusFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
