//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'complaint_comment_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComplaintCommentInput {
  /// Returns a new [ComplaintCommentInput] instance.
  ComplaintCommentInput({required this.body});

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ComplaintCommentInput &&
            runtimeType == other.runtimeType &&
            equals([body], [other.body]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([body]);

  factory ComplaintCommentInput.fromJson(Map<String, dynamic> json) =>
      _$ComplaintCommentInputFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintCommentInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
