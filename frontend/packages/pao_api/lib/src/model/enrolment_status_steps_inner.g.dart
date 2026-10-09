// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrolment_status_steps_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EnrolmentStatusStepsInnerCWProxy {
  EnrolmentStatusStepsInner step(EnrolmentStep step);

  EnrolmentStatusStepsInner done(bool done);

  EnrolmentStatusStepsInner required_(bool required_);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EnrolmentStatusStepsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EnrolmentStatusStepsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  EnrolmentStatusStepsInner call({
    EnrolmentStep step,
    bool done,
    bool required_,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEnrolmentStatusStepsInner.copyWith(...)` or call `instanceOfEnrolmentStatusStepsInner.copyWith.fieldName(value)` for a single field.
class _$EnrolmentStatusStepsInnerCWProxyImpl
    implements _$EnrolmentStatusStepsInnerCWProxy {
  const _$EnrolmentStatusStepsInnerCWProxyImpl(this._value);

  final EnrolmentStatusStepsInner _value;

  @override
  EnrolmentStatusStepsInner step(EnrolmentStep step) => call(step: step);

  @override
  EnrolmentStatusStepsInner done(bool done) => call(done: done);

  @override
  EnrolmentStatusStepsInner required_(bool required_) =>
      call(required_: required_);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EnrolmentStatusStepsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EnrolmentStatusStepsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EnrolmentStatusStepsInner call({
    Object? step = const $CopyWithPlaceholder(),
    Object? done = const $CopyWithPlaceholder(),
    Object? required_ = const $CopyWithPlaceholder(),
  }) {
    return EnrolmentStatusStepsInner(
      step: step == const $CopyWithPlaceholder() || step == null
          ? _value.step
          // ignore: cast_nullable_to_non_nullable
          : step as EnrolmentStep,
      done: done == const $CopyWithPlaceholder() || done == null
          ? _value.done
          // ignore: cast_nullable_to_non_nullable
          : done as bool,
      required_: required_ == const $CopyWithPlaceholder() || required_ == null
          ? _value.required_
          // ignore: cast_nullable_to_non_nullable
          : required_ as bool,
    );
  }
}

extension $EnrolmentStatusStepsInnerCopyWith on EnrolmentStatusStepsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEnrolmentStatusStepsInner.copyWith(...)` or `instanceOfEnrolmentStatusStepsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EnrolmentStatusStepsInnerCWProxy get copyWith =>
      _$EnrolmentStatusStepsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrolmentStatusStepsInner _$EnrolmentStatusStepsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EnrolmentStatusStepsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['step', 'done', 'required']);
  final val = EnrolmentStatusStepsInner(
    step: $checkedConvert(
      'step',
      (v) => $enumDecode(_$EnrolmentStepEnumMap, v),
    ),
    done: $checkedConvert('done', (v) => v as bool),
    required_: $checkedConvert('required', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'required_': 'required'});

Map<String, dynamic> _$EnrolmentStatusStepsInnerToJson(
  EnrolmentStatusStepsInner instance,
) => <String, dynamic>{
  'step': _$EnrolmentStepEnumMap[instance.step]!,
  'done': instance.done,
  'required': instance.required_,
};

const _$EnrolmentStepEnumMap = {
  EnrolmentStep.personal: 'personal',
  EnrolmentStep.services: 'services',
  EnrolmentStep.area: 'area',
  EnrolmentStep.nid: 'nid',
  EnrolmentStep.selfie: 'selfie',
  EnrolmentStep.policeClearance: 'police_clearance',
  EnrolmentStep.skillProof: 'skill_proof',
  EnrolmentStep.emergencyContact: 'emergency_contact',
  EnrolmentStep.codeOfConduct: 'code_of_conduct',
};
