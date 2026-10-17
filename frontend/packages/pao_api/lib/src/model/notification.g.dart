// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NotificationCWProxy {
  Notification id(String id);

  Notification type(String type);

  Notification title(String title);

  Notification body(String body);

  Notification bookingId(String? bookingId);

  Notification read(bool read);

  Notification createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Notification(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Notification(...).copyWith(id: 12, name: "My name")
  /// ```
  Notification call({
    String id,
    String type,
    String title,
    String body,
    String? bookingId,
    bool read,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNotification.copyWith(...)` or call `instanceOfNotification.copyWith.fieldName(value)` for a single field.
class _$NotificationCWProxyImpl implements _$NotificationCWProxy {
  const _$NotificationCWProxyImpl(this._value);

  final Notification _value;

  @override
  Notification id(String id) => call(id: id);

  @override
  Notification type(String type) => call(type: type);

  @override
  Notification title(String title) => call(title: title);

  @override
  Notification body(String body) => call(body: body);

  @override
  Notification bookingId(String? bookingId) => call(bookingId: bookingId);

  @override
  Notification read(bool read) => call(read: read);

  @override
  Notification createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Notification(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Notification(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Notification call({
    Object? id = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? bookingId = const $CopyWithPlaceholder(),
    Object? read = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Notification(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      body: body == const $CopyWithPlaceholder() || body == null
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      bookingId: bookingId == const $CopyWithPlaceholder()
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String?,
      read: read == const $CopyWithPlaceholder() || read == null
          ? _value.read
          // ignore: cast_nullable_to_non_nullable
          : read as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $NotificationCopyWith on Notification {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNotification.copyWith(...)` or `instanceOfNotification.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NotificationCWProxy get copyWith => _$NotificationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Notification', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'type', 'title', 'body', 'read', 'createdAt'],
  );
  final val = Notification(
    id: $checkedConvert('id', (v) => v as String),
    type: $checkedConvert('type', (v) => v as String),
    title: $checkedConvert('title', (v) => v as String),
    body: $checkedConvert('body', (v) => v as String),
    bookingId: $checkedConvert('bookingId', (v) => v as String?),
    read: $checkedConvert('read', (v) => v as bool),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'bookingId': ?instance.bookingId,
      'read': instance.read,
      'createdAt': instance.createdAt.toIso8601String(),
    };
