// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_queue.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VerificationQueueCWProxy {
  VerificationQueue items(List<VerificationQueueItem> items);

  VerificationQueue nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationQueue(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationQueue(...).copyWith(id: 12, name: "My name")
  /// ```
  VerificationQueue call({
    List<VerificationQueueItem> items,
    String? nextCursor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVerificationQueue.copyWith(...)` or call `instanceOfVerificationQueue.copyWith.fieldName(value)` for a single field.
class _$VerificationQueueCWProxyImpl implements _$VerificationQueueCWProxy {
  const _$VerificationQueueCWProxyImpl(this._value);

  final VerificationQueue _value;

  @override
  VerificationQueue items(List<VerificationQueueItem> items) =>
      call(items: items);

  @override
  VerificationQueue nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationQueue(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationQueue(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VerificationQueue call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return VerificationQueue(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<VerificationQueueItem>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $VerificationQueueCopyWith on VerificationQueue {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVerificationQueue.copyWith(...)` or `instanceOfVerificationQueue.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VerificationQueueCWProxy get copyWith =>
      _$VerificationQueueCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationQueue _$VerificationQueueFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VerificationQueue', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = VerificationQueue(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    VerificationQueueItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$VerificationQueueToJson(VerificationQueue instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
