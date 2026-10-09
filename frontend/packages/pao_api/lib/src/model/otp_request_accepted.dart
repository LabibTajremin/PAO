//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'otp_request_accepted.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OtpRequestAccepted {
  /// Returns a new [OtpRequestAccepted] instance.
  OtpRequestAccepted({
    required this.expiresInSeconds,

    required this.resendAfterSeconds,
  });

  @JsonKey(name: r'expiresInSeconds', required: true, includeIfNull: false)
  final int expiresInSeconds;

  @JsonKey(name: r'resendAfterSeconds', required: true, includeIfNull: false)
  final int resendAfterSeconds;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OtpRequestAccepted &&
            runtimeType == other.runtimeType &&
            equals(
              [expiresInSeconds, resendAfterSeconds],
              [other.expiresInSeconds, other.resendAfterSeconds],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([expiresInSeconds, resendAfterSeconds]);

  factory OtpRequestAccepted.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestAcceptedFromJson(json);

  Map<String, dynamic> toJson() => _$OtpRequestAcceptedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
