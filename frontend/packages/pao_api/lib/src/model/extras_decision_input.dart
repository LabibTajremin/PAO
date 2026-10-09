//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'extras_decision_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExtrasDecisionInput {
  /// Returns a new [ExtrasDecisionInput] instance.
  ExtrasDecisionInput({required this.proposalId, required this.approve});

  @JsonKey(name: r'proposalId', required: true, includeIfNull: false)
  final String proposalId;

  @JsonKey(name: r'approve', required: true, includeIfNull: false)
  final bool approve;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExtrasDecisionInput &&
            runtimeType == other.runtimeType &&
            equals([proposalId, approve], [other.proposalId, other.approve]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([proposalId, approve]);

  factory ExtrasDecisionInput.fromJson(Map<String, dynamic> json) =>
      _$ExtrasDecisionInputFromJson(json);

  Map<String, dynamic> toJson() => _$ExtrasDecisionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
