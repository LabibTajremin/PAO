// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nid_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NidInputCWProxy {
  NidInput nidNumber(String nidNumber);

  NidInput frontMediaId(String frontMediaId);

  NidInput backMediaId(String backMediaId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NidInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NidInput(...).copyWith(id: 12, name: "My name")
  /// ```
  NidInput call({String nidNumber, String frontMediaId, String backMediaId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNidInput.copyWith(...)` or call `instanceOfNidInput.copyWith.fieldName(value)` for a single field.
class _$NidInputCWProxyImpl implements _$NidInputCWProxy {
  const _$NidInputCWProxyImpl(this._value);

  final NidInput _value;

  @override
  NidInput nidNumber(String nidNumber) => call(nidNumber: nidNumber);

  @override
  NidInput frontMediaId(String frontMediaId) =>
      call(frontMediaId: frontMediaId);

  @override
  NidInput backMediaId(String backMediaId) => call(backMediaId: backMediaId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NidInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NidInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  NidInput call({
    Object? nidNumber = const $CopyWithPlaceholder(),
    Object? frontMediaId = const $CopyWithPlaceholder(),
    Object? backMediaId = const $CopyWithPlaceholder(),
  }) {
    return NidInput(
      nidNumber: nidNumber == const $CopyWithPlaceholder() || nidNumber == null
          ? _value.nidNumber
          // ignore: cast_nullable_to_non_nullable
          : nidNumber as String,
      frontMediaId:
          frontMediaId == const $CopyWithPlaceholder() || frontMediaId == null
          ? _value.frontMediaId
          // ignore: cast_nullable_to_non_nullable
          : frontMediaId as String,
      backMediaId:
          backMediaId == const $CopyWithPlaceholder() || backMediaId == null
          ? _value.backMediaId
          // ignore: cast_nullable_to_non_nullable
          : backMediaId as String,
    );
  }
}

extension $NidInputCopyWith on NidInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNidInput.copyWith(...)` or `instanceOfNidInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NidInputCWProxy get copyWith => _$NidInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NidInput _$NidInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NidInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['nidNumber', 'frontMediaId', 'backMediaId'],
      );
      final val = NidInput(
        nidNumber: $checkedConvert('nidNumber', (v) => v as String),
        frontMediaId: $checkedConvert('frontMediaId', (v) => v as String),
        backMediaId: $checkedConvert('backMediaId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$NidInputToJson(NidInput instance) => <String, dynamic>{
  'nidNumber': instance.nidNumber,
  'frontMediaId': instance.frontMediaId,
  'backMediaId': instance.backMediaId,
};
