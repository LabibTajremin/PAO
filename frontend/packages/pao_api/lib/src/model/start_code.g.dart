// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_code.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StartCodeCWProxy {
  StartCode code(String code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartCode(...).copyWith(id: 12, name: "My name")
  /// ```
  StartCode call({String code});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStartCode.copyWith(...)` or call `instanceOfStartCode.copyWith.fieldName(value)` for a single field.
class _$StartCodeCWProxyImpl implements _$StartCodeCWProxy {
  const _$StartCodeCWProxyImpl(this._value);

  final StartCode _value;

  @override
  StartCode code(String code) => call(code: code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartCode(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StartCode call({Object? code = const $CopyWithPlaceholder()}) {
    return StartCode(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $StartCodeCopyWith on StartCode {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStartCode.copyWith(...)` or `instanceOfStartCode.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StartCodeCWProxy get copyWith => _$StartCodeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartCode _$StartCodeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StartCode', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code']);
      final val = StartCode(code: $checkedConvert('code', (v) => v as String));
      return val;
    });

Map<String, dynamic> _$StartCodeToJson(StartCode instance) => <String, dynamic>{
  'code': instance.code,
};
