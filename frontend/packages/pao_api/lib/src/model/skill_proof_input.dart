//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'skill_proof_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillProofInput {
  /// Returns a new [SkillProofInput] instance.
  SkillProofInput({required this.mediaIds});

  @JsonKey(name: r'mediaIds', required: true, includeIfNull: false)
  final List<String> mediaIds;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SkillProofInput &&
            runtimeType == other.runtimeType &&
            equals([mediaIds], [other.mediaIds]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([mediaIds]);

  factory SkillProofInput.fromJson(Map<String, dynamic> json) =>
      _$SkillProofInputFromJson(json);

  Map<String, dynamic> toJson() => _$SkillProofInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
