//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/review_tag.dart';
import 'package:pao_api/src/model/localized_text.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'review.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Review {
  /// Returns a new [Review] instance.
  Review({
    required this.id,

    required this.bookingId,

    required this.stars,

    required this.tags,

    this.comment,

    required this.authorName,

    this.serviceName,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'bookingId', required: true, includeIfNull: false)
  final String bookingId;

  @JsonKey(name: r'stars', required: true, includeIfNull: false)
  final int stars;

  @JsonKey(name: r'tags', required: true, includeIfNull: false)
  final List<ReviewTag> tags;

  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  /// First name only.
  @JsonKey(name: r'authorName', required: true, includeIfNull: false)
  final String authorName;

  @JsonKey(name: r'serviceName', required: false, includeIfNull: false)
  final LocalizedText? serviceName;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Review &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                bookingId,
                stars,
                tags,
                comment,
                authorName,
                serviceName,
                createdAt,
              ],
              [
                other.id,
                other.bookingId,
                other.stars,
                other.tags,
                other.comment,
                other.authorName,
                other.serviceName,
                other.createdAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        bookingId,
        stars,
        tags,
        comment,
        authorName,
        serviceName,
        createdAt,
      ]);

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
