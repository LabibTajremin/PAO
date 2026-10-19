// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LedgerEntryListCWProxy {
  LedgerEntryList items(List<LedgerEntry> items);

  LedgerEntryList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LedgerEntryList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LedgerEntryList(...).copyWith(id: 12, name: "My name")
  /// ```
  LedgerEntryList call({List<LedgerEntry> items, String? nextCursor});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLedgerEntryList.copyWith(...)` or call `instanceOfLedgerEntryList.copyWith.fieldName(value)` for a single field.
class _$LedgerEntryListCWProxyImpl implements _$LedgerEntryListCWProxy {
  const _$LedgerEntryListCWProxyImpl(this._value);

  final LedgerEntryList _value;

  @override
  LedgerEntryList items(List<LedgerEntry> items) => call(items: items);

  @override
  LedgerEntryList nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LedgerEntryList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LedgerEntryList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LedgerEntryList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return LedgerEntryList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<LedgerEntry>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $LedgerEntryListCopyWith on LedgerEntryList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLedgerEntryList.copyWith(...)` or `instanceOfLedgerEntryList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LedgerEntryListCWProxy get copyWith => _$LedgerEntryListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerEntryList _$LedgerEntryListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LedgerEntryList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = LedgerEntryList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$LedgerEntryListToJson(LedgerEntryList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
