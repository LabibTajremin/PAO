//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'totp_enrolment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TotpEnrolment {
  /// Returns a new [TotpEnrolment] instance.
  TotpEnrolment({required this.secret, required this.otpauthUrl});

  @JsonKey(name: r'secret', required: true, includeIfNull: false)
  final String secret;

  @JsonKey(name: r'otpauthUrl', required: true, includeIfNull: false)
  final String otpauthUrl;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TotpEnrolment &&
            runtimeType == other.runtimeType &&
            equals([secret, otpauthUrl], [other.secret, other.otpauthUrl]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([secret, otpauthUrl]);

  factory TotpEnrolment.fromJson(Map<String, dynamic> json) =>
      _$TotpEnrolmentFromJson(json);

  Map<String, dynamic> toJson() => _$TotpEnrolmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
