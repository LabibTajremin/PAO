// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_of_conduct_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CodeOfConductInputCWProxy {
  CodeOfConductInput version(String version);

  CodeOfConductInput accepted(bool accepted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CodeOfConductInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CodeOfConductInput(...).copyWith(id: 12, name: "My name")
  /// ```
  CodeOfConductInput call({String version, bool accepted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCodeOfConductInput.copyWith(...)` or call `instanceOfCodeOfConductInput.copyWith.fieldName(value)` for a single field.
class _$CodeOfConductInputCWProxyImpl implements _$CodeOfConductInputCWProxy {
  const _$CodeOfConductInputCWProxyImpl(this._value);

  final CodeOfConductInput _value;

  @override
  CodeOfConductInput version(String version) => call(version: version);

  @override
  CodeOfConductInput accepted(bool accepted) => call(accepted: accepted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CodeOfConductInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CodeOfConductInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CodeOfConductInput call({
    Object? version = const $CopyWithPlaceholder(),
    Object? accepted = const $CopyWithPlaceholder(),
  }) {
    return CodeOfConductInput(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      accepted: accepted == const $CopyWithPlaceholder() || accepted == null
          ? _value.accepted
          // ignore: cast_nullable_to_non_nullable
          : accepted as bool,
    );
  }
}

extension $CodeOfConductInputCopyWith on CodeOfConductInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCodeOfConductInput.copyWith(...)` or `instanceOfCodeOfConductInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CodeOfConductInputCWProxy get copyWith =>
      _$CodeOfConductInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodeOfConductInput _$CodeOfConductInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CodeOfConductInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['version', 'accepted']);
      final val = CodeOfConductInput(
        version: $checkedConvert('version', (v) => v as String),
        accepted: $checkedConvert('accepted', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$CodeOfConductInputToJson(CodeOfConductInput instance) =>
    <String, dynamic>{
      'version': instance.version,
      'accepted': instance.accepted,
    };
