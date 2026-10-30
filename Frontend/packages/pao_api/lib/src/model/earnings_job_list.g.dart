// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_job_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EarningsJobListCWProxy {
  EarningsJobList items(List<EarningsJob> items);

  EarningsJobList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EarningsJobList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EarningsJobList(...).copyWith(id: 12, name: "My name")
  /// ```
  EarningsJobList call({List<EarningsJob> items, String? nextCursor});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEarningsJobList.copyWith(...)` or call `instanceOfEarningsJobList.copyWith.fieldName(value)` for a single field.
class _$EarningsJobListCWProxyImpl implements _$EarningsJobListCWProxy {
  const _$EarningsJobListCWProxyImpl(this._value);

  final EarningsJobList _value;

  @override
  EarningsJobList items(List<EarningsJob> items) => call(items: items);

  @override
  EarningsJobList nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EarningsJobList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EarningsJobList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EarningsJobList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return EarningsJobList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<EarningsJob>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $EarningsJobListCopyWith on EarningsJobList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEarningsJobList.copyWith(...)` or `instanceOfEarningsJobList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EarningsJobListCWProxy get copyWith => _$EarningsJobListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EarningsJobList _$EarningsJobListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EarningsJobList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = EarningsJobList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => EarningsJob.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$EarningsJobListToJson(EarningsJobList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
