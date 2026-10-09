//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/enrolment_step.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'enrolment_status_steps_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EnrolmentStatusStepsInner {
  /// Returns a new [EnrolmentStatusStepsInner] instance.
  EnrolmentStatusStepsInner({
    required this.step,

    required this.done,

    required this.required_,
  });

  @JsonKey(name: r'step', required: true, includeIfNull: false)
  final EnrolmentStep step;

  @JsonKey(name: r'done', required: true, includeIfNull: false)
  final bool done;

  /// Skill proof is optional for Level 1.
  @JsonKey(name: r'required', required: true, includeIfNull: false)
  final bool required_;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnrolmentStatusStepsInner &&
            runtimeType == other.runtimeType &&
            equals(
              [step, done, required_],
              [other.step, other.done, other.required_],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([step, done, required_]);

  factory EnrolmentStatusStepsInner.fromJson(Map<String, dynamic> json) =>
      _$EnrolmentStatusStepsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$EnrolmentStatusStepsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
