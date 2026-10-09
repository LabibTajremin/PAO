// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_reason.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StatusReasonCWProxy {
  StatusReason reason(String reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StatusReason(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StatusReason(...).copyWith(id: 12, name: "My name")
  /// ```
  StatusReason call({String reason});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStatusReason.copyWith(...)` or call `instanceOfStatusReason.copyWith.fieldName(value)` for a single field.
class _$StatusReasonCWProxyImpl implements _$StatusReasonCWProxy {
  const _$StatusReasonCWProxyImpl(this._value);

  final StatusReason _value;

  @override
  StatusReason reason(String reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StatusReason(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StatusReason(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StatusReason call({Object? reason = const $CopyWithPlaceholder()}) {
    return StatusReason(
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $StatusReasonCopyWith on StatusReason {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStatusReason.copyWith(...)` or `instanceOfStatusReason.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StatusReasonCWProxy get copyWith => _$StatusReasonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatusReason _$StatusReasonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StatusReason', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = StatusReason(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$StatusReasonToJson(StatusReason instance) =>
    <String, dynamic>{'reason': instance.reason};
