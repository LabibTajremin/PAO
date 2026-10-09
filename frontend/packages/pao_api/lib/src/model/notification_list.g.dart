// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NotificationListCWProxy {
  NotificationList items(List<Notification> items);

  NotificationList unreadCount(int unreadCount);

  NotificationList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NotificationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NotificationList(...).copyWith(id: 12, name: "My name")
  /// ```
  NotificationList call({
    List<Notification> items,
    int unreadCount,
    String? nextCursor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNotificationList.copyWith(...)` or call `instanceOfNotificationList.copyWith.fieldName(value)` for a single field.
class _$NotificationListCWProxyImpl implements _$NotificationListCWProxy {
  const _$NotificationListCWProxyImpl(this._value);

  final NotificationList _value;

  @override
  NotificationList items(List<Notification> items) => call(items: items);

  @override
  NotificationList unreadCount(int unreadCount) =>
      call(unreadCount: unreadCount);

  @override
  NotificationList nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NotificationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NotificationList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  NotificationList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? unreadCount = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return NotificationList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Notification>,
      unreadCount:
          unreadCount == const $CopyWithPlaceholder() || unreadCount == null
          ? _value.unreadCount
          // ignore: cast_nullable_to_non_nullable
          : unreadCount as int,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $NotificationListCopyWith on NotificationList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNotificationList.copyWith(...)` or `instanceOfNotificationList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NotificationListCWProxy get copyWith => _$NotificationListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationList _$NotificationListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NotificationList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'unreadCount']);
      final val = NotificationList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Notification.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        unreadCount: $checkedConvert('unreadCount', (v) => (v as num).toInt()),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$NotificationListToJson(NotificationList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'unreadCount': instance.unreadCount,
      'nextCursor': ?instance.nextCursor,
    };
