//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/otp_purpose.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'otp_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OtpRequest {
  /// Returns a new [OtpRequest] instance.
  OtpRequest({required this.phone, this.purpose});

  /// Bangladeshi mobile number; the API normalises to +8801XXXXXXXXX.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'purpose', required: false, includeIfNull: false)
  final OtpPurpose? purpose;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OtpRequest &&
            runtimeType == other.runtimeType &&
            equals([phone, purpose], [other.phone, other.purpose]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([phone, purpose]);

  factory OtpRequest.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OtpRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
