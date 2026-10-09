//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/complaint_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'complaint_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComplaintInput {
  /// Returns a new [ComplaintInput] instance.
  ComplaintInput({
    required this.reason,

    required this.description,

    this.photoMediaIds,
  });

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final ComplaintReason reason;

  @JsonKey(name: r'description', required: true, includeIfNull: false)
  final String description;

  @JsonKey(name: r'photoMediaIds', required: false, includeIfNull: false)
  final List<String>? photoMediaIds;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ComplaintInput &&
            runtimeType == other.runtimeType &&
            equals(
              [reason, description, photoMediaIds],
              [other.reason, other.description, other.photoMediaIds],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([reason, description, photoMediaIds]);

  factory ComplaintInput.fromJson(Map<String, dynamic> json) =>
      _$ComplaintInputFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
