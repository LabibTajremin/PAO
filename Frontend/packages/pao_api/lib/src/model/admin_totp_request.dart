//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_totp_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTotpRequest {
  /// Returns a new [AdminTotpRequest] instance.
  AdminTotpRequest({required this.challengeId, required this.code});

  @JsonKey(name: r'challengeId', required: true, includeIfNull: false)
  final String challengeId;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminTotpRequest &&
            runtimeType == other.runtimeType &&
            equals([challengeId, code], [other.challengeId, other.code]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([challengeId, code]);

  factory AdminTotpRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminTotpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminTotpRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
