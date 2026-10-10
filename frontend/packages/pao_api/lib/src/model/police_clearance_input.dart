//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'police_clearance_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PoliceClearanceInput {
  /// Returns a new [PoliceClearanceInput] instance.
  PoliceClearanceInput({required this.mediaId, required this.issueDate});

  @JsonKey(name: r'mediaId', required: true, includeIfNull: false)
  final String mediaId;

  @JsonKey(name: r'issueDate', required: true, includeIfNull: false)
  final String issueDate;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PoliceClearanceInput &&
            runtimeType == other.runtimeType &&
            equals([mediaId, issueDate], [other.mediaId, other.issueDate]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([mediaId, issueDate]);

  factory PoliceClearanceInput.fromJson(Map<String, dynamic> json) =>
      _$PoliceClearanceInputFromJson(json);

  Map<String, dynamic> toJson() => _$PoliceClearanceInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
