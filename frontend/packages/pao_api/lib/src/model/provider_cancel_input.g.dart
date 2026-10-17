// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_cancel_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderCancelInputCWProxy {
  ProviderCancelInput reason(ProviderCancelInputReasonEnum reason);

  ProviderCancelInput note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderCancelInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderCancelInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderCancelInput call({
    ProviderCancelInputReasonEnum reason,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderCancelInput.copyWith(...)` or call `instanceOfProviderCancelInput.copyWith.fieldName(value)` for a single field.
class _$ProviderCancelInputCWProxyImpl implements _$ProviderCancelInputCWProxy {
  const _$ProviderCancelInputCWProxyImpl(this._value);

  final ProviderCancelInput _value;

  @override
  ProviderCancelInput reason(ProviderCancelInputReasonEnum reason) =>
      call(reason: reason);

  @override
  ProviderCancelInput note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderCancelInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderCancelInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderCancelInput call({
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return ProviderCancelInput(
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as ProviderCancelInputReasonEnum,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $ProviderCancelInputCopyWith on ProviderCancelInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderCancelInput.copyWith(...)` or `instanceOfProviderCancelInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderCancelInputCWProxy get copyWith =>
      _$ProviderCancelInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderCancelInput _$ProviderCancelInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProviderCancelInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = ProviderCancelInput(
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$ProviderCancelInputReasonEnumEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ProviderCancelInputToJson(
  ProviderCancelInput instance,
) => <String, dynamic>{
  'reason': _$ProviderCancelInputReasonEnumEnumMap[instance.reason]!,
  'note': ?instance.note,
};

const _$ProviderCancelInputReasonEnumEnumMap = {
  ProviderCancelInputReasonEnum.emergency: 'emergency',
  ProviderCancelInputReasonEnum.customerUnreachable: 'customer_unreachable',
  ProviderCancelInputReasonEnum.unsafeLocation: 'unsafe_location',
  ProviderCancelInputReasonEnum.other: 'other',
};
