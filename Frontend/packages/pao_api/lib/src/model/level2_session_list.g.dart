// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level2_session_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Level2SessionListCWProxy {
  Level2SessionList items(List<Level2Session> items);

  Level2SessionList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2SessionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2SessionList(...).copyWith(id: 12, name: "My name")
  /// ```
  Level2SessionList call({List<Level2Session> items, String? nextCursor});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLevel2SessionList.copyWith(...)` or call `instanceOfLevel2SessionList.copyWith.fieldName(value)` for a single field.
class _$Level2SessionListCWProxyImpl implements _$Level2SessionListCWProxy {
  const _$Level2SessionListCWProxyImpl(this._value);

  final Level2SessionList _value;

  @override
  Level2SessionList items(List<Level2Session> items) => call(items: items);

  @override
  Level2SessionList nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2SessionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2SessionList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Level2SessionList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return Level2SessionList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Level2Session>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $Level2SessionListCopyWith on Level2SessionList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLevel2SessionList.copyWith(...)` or `instanceOfLevel2SessionList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Level2SessionListCWProxy get copyWith =>
      _$Level2SessionListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level2SessionList _$Level2SessionListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Level2SessionList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = Level2SessionList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Level2Session.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$Level2SessionListToJson(Level2SessionList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
