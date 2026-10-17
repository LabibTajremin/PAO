//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/service_ref.dart';
import 'package:pao_api/src/model/item_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'verification_queue_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerificationQueueItem {
  /// Returns a new [VerificationQueueItem] instance.
  VerificationQueueItem({
    required this.providerId,

    required this.name,

    this.services,

    required this.pendingItems,

    required this.submittedAt,

    required this.ageHours,
  });

  @JsonKey(name: r'providerId', required: true, includeIfNull: false)
  final String providerId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'services', required: false, includeIfNull: false)
  final List<ServiceRef>? services;

  @JsonKey(name: r'pendingItems', required: true, includeIfNull: false)
  final List<ItemType> pendingItems;

  @JsonKey(name: r'submittedAt', required: true, includeIfNull: false)
  final DateTime submittedAt;

  @JsonKey(name: r'ageHours', required: true, includeIfNull: false)
  final int ageHours;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VerificationQueueItem &&
            runtimeType == other.runtimeType &&
            equals(
              [providerId, name, services, pendingItems, submittedAt, ageHours],
              [
                other.providerId,
                other.name,
                other.services,
                other.pendingItems,
                other.submittedAt,
                other.ageHours,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        providerId,
        name,
        services,
        pendingItems,
        submittedAt,
        ageHours,
      ]);

  factory VerificationQueueItem.fromJson(Map<String, dynamic> json) =>
      _$VerificationQueueItemFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationQueueItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
