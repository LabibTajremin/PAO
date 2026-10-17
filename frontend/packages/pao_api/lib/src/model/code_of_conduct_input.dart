//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'code_of_conduct_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CodeOfConductInput {
  /// Returns a new [CodeOfConductInput] instance.
  CodeOfConductInput({required this.version, required this.accepted});

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  /// Must be true.
  @JsonKey(name: r'accepted', required: true, includeIfNull: false)
  final bool accepted;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CodeOfConductInput &&
            runtimeType == other.runtimeType &&
            equals([version, accepted], [other.version, other.accepted]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([version, accepted]);

  factory CodeOfConductInput.fromJson(Map<String, dynamic> json) =>
      _$CodeOfConductInputFromJson(json);

  Map<String, dynamic> toJson() => _$CodeOfConductInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
