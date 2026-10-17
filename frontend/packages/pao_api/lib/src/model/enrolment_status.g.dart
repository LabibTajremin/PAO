// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrolment_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EnrolmentStatusCWProxy {
  EnrolmentStatus steps(List<EnrolmentStatusStepsInner> steps);

  EnrolmentStatus complete(bool complete);

  EnrolmentStatus submitted(bool submitted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EnrolmentStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EnrolmentStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  EnrolmentStatus call({
    List<EnrolmentStatusStepsInner> steps,
    bool complete,
    bool submitted,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEnrolmentStatus.copyWith(...)` or call `instanceOfEnrolmentStatus.copyWith.fieldName(value)` for a single field.
class _$EnrolmentStatusCWProxyImpl implements _$EnrolmentStatusCWProxy {
  const _$EnrolmentStatusCWProxyImpl(this._value);

  final EnrolmentStatus _value;

  @override
  EnrolmentStatus steps(List<EnrolmentStatusStepsInner> steps) =>
      call(steps: steps);

  @override
  EnrolmentStatus complete(bool complete) => call(complete: complete);

  @override
  EnrolmentStatus submitted(bool submitted) => call(submitted: submitted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EnrolmentStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EnrolmentStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EnrolmentStatus call({
    Object? steps = const $CopyWithPlaceholder(),
    Object? complete = const $CopyWithPlaceholder(),
    Object? submitted = const $CopyWithPlaceholder(),
  }) {
    return EnrolmentStatus(
      steps: steps == const $CopyWithPlaceholder() || steps == null
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<EnrolmentStatusStepsInner>,
      complete: complete == const $CopyWithPlaceholder() || complete == null
          ? _value.complete
          // ignore: cast_nullable_to_non_nullable
          : complete as bool,
      submitted: submitted == const $CopyWithPlaceholder() || submitted == null
          ? _value.submitted
          // ignore: cast_nullable_to_non_nullable
          : submitted as bool,
    );
  }
}

extension $EnrolmentStatusCopyWith on EnrolmentStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEnrolmentStatus.copyWith(...)` or `instanceOfEnrolmentStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EnrolmentStatusCWProxy get copyWith => _$EnrolmentStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrolmentStatus _$EnrolmentStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EnrolmentStatus', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['steps', 'complete', 'submitted']);
      final val = EnrolmentStatus(
        steps: $checkedConvert(
          'steps',
          (v) => (v as List<dynamic>)
              .map(
                (e) => EnrolmentStatusStepsInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        complete: $checkedConvert('complete', (v) => v as bool),
        submitted: $checkedConvert('submitted', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$EnrolmentStatusToJson(EnrolmentStatus instance) =>
    <String, dynamic>{
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'complete': instance.complete,
      'submitted': instance.submitted,
    };
