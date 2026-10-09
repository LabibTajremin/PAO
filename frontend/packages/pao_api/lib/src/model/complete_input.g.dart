// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CompleteInputCWProxy {
  CompleteInput cashReceived(bool cashReceived);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CompleteInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CompleteInput(...).copyWith(id: 12, name: "My name")
  /// ```
  CompleteInput call({bool cashReceived});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCompleteInput.copyWith(...)` or call `instanceOfCompleteInput.copyWith.fieldName(value)` for a single field.
class _$CompleteInputCWProxyImpl implements _$CompleteInputCWProxy {
  const _$CompleteInputCWProxyImpl(this._value);

  final CompleteInput _value;

  @override
  CompleteInput cashReceived(bool cashReceived) =>
      call(cashReceived: cashReceived);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CompleteInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CompleteInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CompleteInput call({Object? cashReceived = const $CopyWithPlaceholder()}) {
    return CompleteInput(
      cashReceived:
          cashReceived == const $CopyWithPlaceholder() || cashReceived == null
          ? _value.cashReceived
          // ignore: cast_nullable_to_non_nullable
          : cashReceived as bool,
    );
  }
}

extension $CompleteInputCopyWith on CompleteInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCompleteInput.copyWith(...)` or `instanceOfCompleteInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CompleteInputCWProxy get copyWith => _$CompleteInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompleteInput _$CompleteInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CompleteInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['cashReceived']);
      final val = CompleteInput(
        cashReceived: $checkedConvert('cashReceived', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$CompleteInputToJson(CompleteInput instance) =>
    <String, dynamic>{'cashReceived': instance.cashReceived};
