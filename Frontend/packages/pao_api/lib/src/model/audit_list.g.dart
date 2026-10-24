// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AuditListCWProxy {
  AuditList items(List<AuditEntry> items);

  AuditList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AuditList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AuditList(...).copyWith(id: 12, name: "My name")
  /// ```
  AuditList call({List<AuditEntry> items, String? nextCursor});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAuditList.copyWith(...)` or call `instanceOfAuditList.copyWith.fieldName(value)` for a single field.
class _$AuditListCWProxyImpl implements _$AuditListCWProxy {
  const _$AuditListCWProxyImpl(this._value);

  final AuditList _value;

  @override
  AuditList items(List<AuditEntry> items) => call(items: items);

  @override
  AuditList nextCursor(String? nextCursor) => call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AuditList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AuditList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AuditList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return AuditList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AuditEntry>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $AuditListCopyWith on AuditList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAuditList.copyWith(...)` or `instanceOfAuditList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AuditListCWProxy get copyWith => _$AuditListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditList _$AuditListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AuditList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AuditList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AuditListToJson(AuditList instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
};
