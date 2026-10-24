// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reject_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RejectInputCWProxy {
  RejectInput reason(RejectInputReasonEnum reason);

  RejectInput note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RejectInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RejectInput(...).copyWith(id: 12, name: "My name")
  /// ```
  RejectInput call({RejectInputReasonEnum reason, String? note});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRejectInput.copyWith(...)` or call `instanceOfRejectInput.copyWith.fieldName(value)` for a single field.
class _$RejectInputCWProxyImpl implements _$RejectInputCWProxy {
  const _$RejectInputCWProxyImpl(this._value);

  final RejectInput _value;

  @override
  RejectInput reason(RejectInputReasonEnum reason) => call(reason: reason);

  @override
  RejectInput note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RejectInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RejectInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RejectInput call({
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return RejectInput(
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as RejectInputReasonEnum,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $RejectInputCopyWith on RejectInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRejectInput.copyWith(...)` or `instanceOfRejectInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RejectInputCWProxy get copyWith => _$RejectInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RejectInput _$RejectInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RejectInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = RejectInput(
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$RejectInputReasonEnumEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$RejectInputToJson(RejectInput instance) =>
    <String, dynamic>{
      'reason': _$RejectInputReasonEnumEnumMap[instance.reason]!,
      'note': ?instance.note,
    };

const _$RejectInputReasonEnumEnumMap = {
  RejectInputReasonEnum.busy: 'busy',
  RejectInputReasonEnum.tooFar: 'too_far',
  RejectInputReasonEnum.notMyService: 'not_my_service',
  RejectInputReasonEnum.other: 'other',
};
