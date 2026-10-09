//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/review_tag.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'review_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewInput {
  /// Returns a new [ReviewInput] instance.
  ReviewInput({required this.stars, this.tags, this.comment});

  // minimum: 1
  // maximum: 5
  @JsonKey(name: r'stars', required: true, includeIfNull: false)
  final int stars;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final Set<ReviewTag>? tags;

  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewInput &&
            runtimeType == other.runtimeType &&
            equals(
              [stars, tags, comment],
              [other.stars, other.tags, other.comment],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([stars, tags, comment]);

  factory ReviewInput.fromJson(Map<String, dynamic> json) =>
      _$ReviewInputFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
