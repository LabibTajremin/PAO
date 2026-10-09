// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_resolve_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComplaintResolveInputCWProxy {
  ComplaintResolveInput resolution(String resolution);

  ComplaintResolveInput verified(bool verified);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintResolveInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintResolveInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ComplaintResolveInput call({String resolution, bool verified});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComplaintResolveInput.copyWith(...)` or call `instanceOfComplaintResolveInput.copyWith.fieldName(value)` for a single field.
class _$ComplaintResolveInputCWProxyImpl
    implements _$ComplaintResolveInputCWProxy {
  const _$ComplaintResolveInputCWProxyImpl(this._value);

  final ComplaintResolveInput _value;

  @override
  ComplaintResolveInput resolution(String resolution) =>
      call(resolution: resolution);

  @override
  ComplaintResolveInput verified(bool verified) => call(verified: verified);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintResolveInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintResolveInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComplaintResolveInput call({
    Object? resolution = const $CopyWithPlaceholder(),
    Object? verified = const $CopyWithPlaceholder(),
  }) {
    return ComplaintResolveInput(
      resolution:
          resolution == const $CopyWithPlaceholder() || resolution == null
          ? _value.resolution
          // ignore: cast_nullable_to_non_nullable
          : resolution as String,
      verified: verified == const $CopyWithPlaceholder() || verified == null
          ? _value.verified
          // ignore: cast_nullable_to_non_nullable
          : verified as bool,
    );
  }
}

extension $ComplaintResolveInputCopyWith on ComplaintResolveInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComplaintResolveInput.copyWith(...)` or `instanceOfComplaintResolveInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComplaintResolveInputCWProxy get copyWith =>
      _$ComplaintResolveInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintResolveInput _$ComplaintResolveInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ComplaintResolveInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['resolution', 'verified']);
  final val = ComplaintResolveInput(
    resolution: $checkedConvert('resolution', (v) => v as String),
    verified: $checkedConvert('verified', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$ComplaintResolveInputToJson(
  ComplaintResolveInput instance,
) => <String, dynamic>{
  'resolution': instance.resolution,
  'verified': instance.verified,
};
