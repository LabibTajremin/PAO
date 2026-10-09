//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/notification.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'notification_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationList {
  /// Returns a new [NotificationList] instance.
  NotificationList({
    required this.items,

    required this.unreadCount,

    this.nextCursor,
  });

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<Notification> items;

  @JsonKey(name: r'unreadCount', required: true, includeIfNull: false)
  final int unreadCount;

  /// Opaque cursor for the next page (base64 of created_at and id).
  @JsonKey(name: r'nextCursor', required: false, includeIfNull: false)
  final String? nextCursor;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationList &&
            runtimeType == other.runtimeType &&
            equals(
              [items, unreadCount, nextCursor],
              [other.items, other.unreadCount, other.nextCursor],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([items, unreadCount, nextCursor]);

  factory NotificationList.fromJson(Map<String, dynamic> json) =>
      _$NotificationListFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
