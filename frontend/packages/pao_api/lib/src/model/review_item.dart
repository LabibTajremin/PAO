//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/item_status.dart';
import 'package:pao_api/src/model/review_document.dart';
import 'package:pao_api/src/model/item_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'review_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewItem {
  /// Returns a new [ReviewItem] instance.
  ReviewItem({
    required this.type,

    required this.status,

    required this.required_,

    this.rejectionReason,

    this.expiresAt,

    this.decidedAt,

    this.documents,

    this.fields,
  });

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final ItemType type;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ItemStatus status;

  @JsonKey(name: r'required', required: true, includeIfNull: false)
  final bool required_;

  @JsonKey(name: r'rejectionReason', required: false, includeIfNull: false)
  final String? rejectionReason;

  @JsonKey(name: r'expiresAt', required: false, includeIfNull: false)
  final DateTime? expiresAt;

  @JsonKey(name: r'decidedAt', required: false, includeIfNull: false)
  final DateTime? decidedAt;

  @JsonKey(name: r'documents', required: false, includeIfNull: false)
  final List<ReviewDocument>? documents;

  /// Submitted values to check (e.g. issue date, emergency contact).
  @JsonKey(name: r'fields', required: false, includeIfNull: false)
  final Map<String, String>? fields;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewItem &&
            runtimeType == other.runtimeType &&
            equals(
              [
                type,
                status,
                required_,
                rejectionReason,
                expiresAt,
                decidedAt,
                documents,
                fields,
              ],
              [
                other.type,
                other.status,
                other.required_,
                other.rejectionReason,
                other.expiresAt,
                other.decidedAt,
                other.documents,
                other.fields,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        type,
        status,
        required_,
        rejectionReason,
        expiresAt,
        decidedAt,
        documents,
        fields,
      ]);

  factory ReviewItem.fromJson(Map<String, dynamic> json) =>
      _$ReviewItemFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
