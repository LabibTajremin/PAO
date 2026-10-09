// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selfie_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SelfieInputCWProxy {
  SelfieInput mediaId(String mediaId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SelfieInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SelfieInput(...).copyWith(id: 12, name: "My name")
  /// ```
  SelfieInput call({String mediaId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSelfieInput.copyWith(...)` or call `instanceOfSelfieInput.copyWith.fieldName(value)` for a single field.
class _$SelfieInputCWProxyImpl implements _$SelfieInputCWProxy {
  const _$SelfieInputCWProxyImpl(this._value);

  final SelfieInput _value;

  @override
  SelfieInput mediaId(String mediaId) => call(mediaId: mediaId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SelfieInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SelfieInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SelfieInput call({Object? mediaId = const $CopyWithPlaceholder()}) {
    return SelfieInput(
      mediaId: mediaId == const $CopyWithPlaceholder() || mediaId == null
          ? _value.mediaId
          // ignore: cast_nullable_to_non_nullable
          : mediaId as String,
    );
  }
}

extension $SelfieInputCopyWith on SelfieInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSelfieInput.copyWith(...)` or `instanceOfSelfieInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SelfieInputCWProxy get copyWith => _$SelfieInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SelfieInput _$SelfieInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SelfieInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['mediaId']);
      final val = SelfieInput(
        mediaId: $checkedConvert('mediaId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SelfieInputToJson(SelfieInput instance) =>
    <String, dynamic>{'mediaId': instance.mediaId};
