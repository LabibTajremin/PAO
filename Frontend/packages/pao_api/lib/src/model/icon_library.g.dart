// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'icon_library.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IconLibraryCWProxy {
  IconLibrary keys(List<String> keys);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IconLibrary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IconLibrary(...).copyWith(id: 12, name: "My name")
  /// ```
  IconLibrary call({List<String> keys});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIconLibrary.copyWith(...)` or call `instanceOfIconLibrary.copyWith.fieldName(value)` for a single field.
class _$IconLibraryCWProxyImpl implements _$IconLibraryCWProxy {
  const _$IconLibraryCWProxyImpl(this._value);

  final IconLibrary _value;

  @override
  IconLibrary keys(List<String> keys) => call(keys: keys);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IconLibrary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IconLibrary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IconLibrary call({Object? keys = const $CopyWithPlaceholder()}) {
    return IconLibrary(
      keys: keys == const $CopyWithPlaceholder() || keys == null
          ? _value.keys
          // ignore: cast_nullable_to_non_nullable
          : keys as List<String>,
    );
  }
}

extension $IconLibraryCopyWith on IconLibrary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIconLibrary.copyWith(...)` or `instanceOfIconLibrary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IconLibraryCWProxy get copyWith => _$IconLibraryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IconLibrary _$IconLibraryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IconLibrary', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['keys']);
      final val = IconLibrary(
        keys: $checkedConvert(
          'keys',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$IconLibraryToJson(IconLibrary instance) =>
    <String, dynamic>{'keys': instance.keys};
