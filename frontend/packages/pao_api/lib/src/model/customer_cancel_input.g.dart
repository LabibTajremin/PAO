// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_cancel_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerCancelInputCWProxy {
  CustomerCancelInput reason(CustomerCancelInputReasonEnum reason);

  CustomerCancelInput note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerCancelInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerCancelInput(...).copyWith(id: 12, name: "My name")
  /// ```
  CustomerCancelInput call({
    CustomerCancelInputReasonEnum reason,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCustomerCancelInput.copyWith(...)` or call `instanceOfCustomerCancelInput.copyWith.fieldName(value)` for a single field.
class _$CustomerCancelInputCWProxyImpl implements _$CustomerCancelInputCWProxy {
  const _$CustomerCancelInputCWProxyImpl(this._value);

  final CustomerCancelInput _value;

  @override
  CustomerCancelInput reason(CustomerCancelInputReasonEnum reason) =>
      call(reason: reason);

  @override
  CustomerCancelInput note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerCancelInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerCancelInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CustomerCancelInput call({
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return CustomerCancelInput(
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as CustomerCancelInputReasonEnum,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $CustomerCancelInputCopyWith on CustomerCancelInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCustomerCancelInput.copyWith(...)` or `instanceOfCustomerCancelInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerCancelInputCWProxy get copyWith =>
      _$CustomerCancelInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerCancelInput _$CustomerCancelInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CustomerCancelInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = CustomerCancelInput(
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$CustomerCancelInputReasonEnumEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CustomerCancelInputToJson(
  CustomerCancelInput instance,
) => <String, dynamic>{
  'reason': _$CustomerCancelInputReasonEnumEnumMap[instance.reason]!,
  'note': ?instance.note,
};

const _$CustomerCancelInputReasonEnumEnumMap = {
  CustomerCancelInputReasonEnum.changedMind: 'changed_mind',
  CustomerCancelInputReasonEnum.foundOtherProvider: 'found_other_provider',
  CustomerCancelInputReasonEnum.providerLate: 'provider_late',
  CustomerCancelInputReasonEnum.bookedByMistake: 'booked_by_mistake',
  CustomerCancelInputReasonEnum.other: 'other',
};
