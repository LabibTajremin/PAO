//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/enrolment_status_steps_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'enrolment_status.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EnrolmentStatus {
  /// Returns a new [EnrolmentStatus] instance.
  EnrolmentStatus({
    required this.steps,

    required this.complete,

    required this.submitted,
  });

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<EnrolmentStatusStepsInner> steps;

  /// Every required step is done.
  @JsonKey(name: r'complete', required: true, includeIfNull: false)
  final bool complete;

  @JsonKey(name: r'submitted', required: true, includeIfNull: false)
  final bool submitted;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnrolmentStatus &&
            runtimeType == other.runtimeType &&
            equals(
              [steps, complete, submitted],
              [other.steps, other.complete, other.submitted],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([steps, complete, submitted]);

  factory EnrolmentStatus.fromJson(Map<String, dynamic> json) =>
      _$EnrolmentStatusFromJson(json);

  Map<String, dynamic> toJson() => _$EnrolmentStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
