//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/verification_review_profile.dart';
import 'package:pao_api/src/model/review_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'verification_review.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerificationReview {
  /// Returns a new [VerificationReview] instance.
  VerificationReview({
    required this.providerId,

    required this.level,

    required this.profile,

    this.faceMatch,

    required this.items,
  });

  @JsonKey(name: r'providerId', required: true, includeIfNull: false)
  final String providerId;

  /// Verification level (PRD §6.1) — 0 Registered, 1 Verified, 2 PAO Verified Pro.
  // minimum: 0
  // maximum: 2
  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final int level;

  @JsonKey(name: r'profile', required: true, includeIfNull: false)
  final VerificationReviewProfile profile;

  /// Result of the face check; the manual adapter leaves it to the verifier (D10).
  @JsonKey(name: r'faceMatch', required: false, includeIfNull: false)
  final VerificationReviewFaceMatchEnum? faceMatch;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ReviewItem> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VerificationReview &&
            runtimeType == other.runtimeType &&
            equals(
              [providerId, level, profile, faceMatch, items],
              [
                other.providerId,
                other.level,
                other.profile,
                other.faceMatch,
                other.items,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([providerId, level, profile, faceMatch, items]);

  factory VerificationReview.fromJson(Map<String, dynamic> json) =>
      _$VerificationReviewFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationReviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Result of the face check; the manual adapter leaves it to the verifier (D10).
enum VerificationReviewFaceMatchEnum {
  /// Result of the face check; the manual adapter leaves it to the verifier (D10).
  @JsonValue(r'not_run')
  notRun(r'not_run'),

  /// Result of the face check; the manual adapter leaves it to the verifier (D10).
  @JsonValue(r'match')
  match(r'match'),

  /// Result of the face check; the manual adapter leaves it to the verifier (D10).
  @JsonValue(r'no_match')
  noMatch(r'no_match'),

  /// Result of the face check; the manual adapter leaves it to the verifier (D10).
  @JsonValue(r'manual_review')
  manualReview(r'manual_review');

  const VerificationReviewFaceMatchEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
