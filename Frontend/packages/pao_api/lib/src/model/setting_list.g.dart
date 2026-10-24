// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SettingListCWProxy {
  SettingList items(List<Setting> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SettingList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SettingList(...).copyWith(id: 12, name: "My name")
  /// ```
  SettingList call({List<Setting> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSettingList.copyWith(...)` or call `instanceOfSettingList.copyWith.fieldName(value)` for a single field.
class _$SettingListCWProxyImpl implements _$SettingListCWProxy {
  const _$SettingListCWProxyImpl(this._value);

  final SettingList _value;

  @override
  SettingList items(List<Setting> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SettingList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SettingList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SettingList call({Object? items = const $CopyWithPlaceholder()}) {
    return SettingList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Setting>,
    );
  }
}

extension $SettingListCopyWith on SettingList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSettingList.copyWith(...)` or `instanceOfSettingList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SettingListCWProxy get copyWith => _$SettingListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingList _$SettingListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SettingList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = SettingList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Setting.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SettingListToJson(SettingList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
