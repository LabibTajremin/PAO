// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AuditEntryCWProxy {
  AuditEntry id(String id);

  AuditEntry at(DateTime at);

  AuditEntry actorId(String? actorId);

  AuditEntry actorRole(String? actorRole);

  AuditEntry action(String action);

  AuditEntry subjectType(String subjectType);

  AuditEntry subjectId(String subjectId);

  AuditEntry reason(String? reason);

  AuditEntry before(Map<String, Object>? before);

  AuditEntry after(Map<String, Object>? after);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AuditEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AuditEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  AuditEntry call({
    String id,
    DateTime at,
    String? actorId,
    String? actorRole,
    String action,
    String subjectType,
    String subjectId,
    String? reason,
    Map<String, Object>? before,
    Map<String, Object>? after,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAuditEntry.copyWith(...)` or call `instanceOfAuditEntry.copyWith.fieldName(value)` for a single field.
class _$AuditEntryCWProxyImpl implements _$AuditEntryCWProxy {
  const _$AuditEntryCWProxyImpl(this._value);

  final AuditEntry _value;

  @override
  AuditEntry id(String id) => call(id: id);

  @override
  AuditEntry at(DateTime at) => call(at: at);

  @override
  AuditEntry actorId(String? actorId) => call(actorId: actorId);

  @override
  AuditEntry actorRole(String? actorRole) => call(actorRole: actorRole);

  @override
  AuditEntry action(String action) => call(action: action);

  @override
  AuditEntry subjectType(String subjectType) => call(subjectType: subjectType);

  @override
  AuditEntry subjectId(String subjectId) => call(subjectId: subjectId);

  @override
  AuditEntry reason(String? reason) => call(reason: reason);

  @override
  AuditEntry before(Map<String, Object>? before) => call(before: before);

  @override
  AuditEntry after(Map<String, Object>? after) => call(after: after);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AuditEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AuditEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AuditEntry call({
    Object? id = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? actorId = const $CopyWithPlaceholder(),
    Object? actorRole = const $CopyWithPlaceholder(),
    Object? action = const $CopyWithPlaceholder(),
    Object? subjectType = const $CopyWithPlaceholder(),
    Object? subjectId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? before = const $CopyWithPlaceholder(),
    Object? after = const $CopyWithPlaceholder(),
  }) {
    return AuditEntry(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      actorId: actorId == const $CopyWithPlaceholder()
          ? _value.actorId
          // ignore: cast_nullable_to_non_nullable
          : actorId as String?,
      actorRole: actorRole == const $CopyWithPlaceholder()
          ? _value.actorRole
          // ignore: cast_nullable_to_non_nullable
          : actorRole as String?,
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as String,
      subjectType:
          subjectType == const $CopyWithPlaceholder() || subjectType == null
          ? _value.subjectType
          // ignore: cast_nullable_to_non_nullable
          : subjectType as String,
      subjectId: subjectId == const $CopyWithPlaceholder() || subjectId == null
          ? _value.subjectId
          // ignore: cast_nullable_to_non_nullable
          : subjectId as String,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      before: before == const $CopyWithPlaceholder()
          ? _value.before
          // ignore: cast_nullable_to_non_nullable
          : before as Map<String, Object>?,
      after: after == const $CopyWithPlaceholder()
          ? _value.after
          // ignore: cast_nullable_to_non_nullable
          : after as Map<String, Object>?,
    );
  }
}

extension $AuditEntryCopyWith on AuditEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAuditEntry.copyWith(...)` or `instanceOfAuditEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AuditEntryCWProxy get copyWith => _$AuditEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEntry _$AuditEntryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AuditEntry', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'at', 'action', 'subjectType', 'subjectId'],
  );
  final val = AuditEntry(
    id: $checkedConvert('id', (v) => v as String),
    at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
    actorId: $checkedConvert('actorId', (v) => v as String?),
    actorRole: $checkedConvert('actorRole', (v) => v as String?),
    action: $checkedConvert('action', (v) => v as String),
    subjectType: $checkedConvert('subjectType', (v) => v as String),
    subjectId: $checkedConvert('subjectId', (v) => v as String),
    reason: $checkedConvert('reason', (v) => v as String?),
    before: $checkedConvert(
      'before',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as Object)),
    ),
    after: $checkedConvert(
      'after',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as Object)),
    ),
  );
  return val;
});

Map<String, dynamic> _$AuditEntryToJson(AuditEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'at': instance.at.toIso8601String(),
      'actorId': ?instance.actorId,
      'actorRole': ?instance.actorRole,
      'action': instance.action,
      'subjectType': instance.subjectType,
      'subjectId': instance.subjectId,
      'reason': ?instance.reason,
      'before': ?instance.before,
      'after': ?instance.after,
    };
