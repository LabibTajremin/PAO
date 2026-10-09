//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/gender.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'verification_review_profile.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerificationReviewProfile {
  /// Returns a new [VerificationReviewProfile] instance.
  VerificationReviewProfile({
    required this.fullName,

    required this.dateOfBirth,

    required this.gender,

    required this.phone,

    this.presentAddress,

    this.permanentAddress,

    this.nidNumber,
  });

  @JsonKey(name: r'fullName', required: true, includeIfNull: false)
  final String fullName;

  @JsonKey(name: r'dateOfBirth', required: true, includeIfNull: false)
  final DateTime dateOfBirth;

  @JsonKey(name: r'gender', required: true, includeIfNull: false)
  final Gender gender;

  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'presentAddress', required: false, includeIfNull: false)
  final String? presentAddress;

  @JsonKey(name: r'permanentAddress', required: false, includeIfNull: false)
  final String? permanentAddress;

  @JsonKey(name: r'nidNumber', required: false, includeIfNull: false)
  final String? nidNumber;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VerificationReviewProfile &&
            runtimeType == other.runtimeType &&
            equals(
              [
                fullName,
                dateOfBirth,
                gender,
                phone,
                presentAddress,
                permanentAddress,
                nidNumber,
              ],
              [
                other.fullName,
                other.dateOfBirth,
                other.gender,
                other.phone,
                other.presentAddress,
                other.permanentAddress,
                other.nidNumber,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        fullName,
        dateOfBirth,
        gender,
        phone,
        presentAddress,
        permanentAddress,
        nidNumber,
      ]);

  factory VerificationReviewProfile.fromJson(Map<String, dynamic> json) =>
      _$VerificationReviewProfileFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationReviewProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
