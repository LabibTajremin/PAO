//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'review_document.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewDocument {
  /// Returns a new [ReviewDocument] instance.
  ReviewDocument({required this.mediaId, required this.kind});

  @JsonKey(name: r'mediaId', required: true, includeIfNull: false)
  final String mediaId;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final String kind;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewDocument &&
            runtimeType == other.runtimeType &&
            equals([mediaId, kind], [other.mediaId, other.kind]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([mediaId, kind]);

  factory ReviewDocument.fromJson(Map<String, dynamic> json) =>
      _$ReviewDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewDocumentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
