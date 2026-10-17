//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'complaint_assign_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComplaintAssignInput {
  /// Returns a new [ComplaintAssignInput] instance.
  ComplaintAssignInput({required this.assigneeId});

  @JsonKey(name: r'assigneeId', required: true, includeIfNull: false)
  final String assigneeId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ComplaintAssignInput &&
            runtimeType == other.runtimeType &&
            equals([assigneeId], [other.assigneeId]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([assigneeId]);

  factory ComplaintAssignInput.fromJson(Map<String, dynamic> json) =>
      _$ComplaintAssignInputFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintAssignInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
