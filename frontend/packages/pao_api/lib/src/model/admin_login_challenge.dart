//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/totp_enrolment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_login_challenge.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminLoginChallenge {
  /// Returns a new [AdminLoginChallenge] instance.
  AdminLoginChallenge({
    required this.challengeId,

    required this.expiresInSeconds,

    this.totpEnrolment,
  });

  @JsonKey(name: r'challengeId', required: true, includeIfNull: false)
  final String challengeId;

  @JsonKey(name: r'expiresInSeconds', required: true, includeIfNull: false)
  final int expiresInSeconds;

  @JsonKey(name: r'totpEnrolment', required: false, includeIfNull: false)
  final TotpEnrolment? totpEnrolment;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminLoginChallenge &&
            runtimeType == other.runtimeType &&
            equals(
              [challengeId, expiresInSeconds, totpEnrolment],
              [other.challengeId, other.expiresInSeconds, other.totpEnrolment],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([challengeId, expiresInSeconds, totpEnrolment]);

  factory AdminLoginChallenge.fromJson(Map<String, dynamic> json) =>
      _$AdminLoginChallengeFromJson(json);

  Map<String, dynamic> toJson() => _$AdminLoginChallengeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
