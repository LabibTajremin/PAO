//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'complaint_comment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComplaintComment {
  /// Returns a new [ComplaintComment] instance.
  ComplaintComment({
    required this.authorId,

    required this.body,

    required this.at,
  });

  @JsonKey(name: r'authorId', required: true, includeIfNull: false)
  final String authorId;

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ComplaintComment &&
            runtimeType == other.runtimeType &&
            equals(
              [authorId, body, at],
              [other.authorId, other.body, other.at],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([authorId, body, at]);

  factory ComplaintComment.fromJson(Map<String, dynamic> json) =>
      _$ComplaintCommentFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintCommentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
