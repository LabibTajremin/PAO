//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/error_code.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'error_body.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ErrorBody {
  /// Returns a new [ErrorBody] instance.
  ErrorBody({required this.code, required this.message, this.details});

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final ErrorCode code;

  /// English description for logs; apps translate `code` instead.
  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  /// Machine-readable context, e.g. the invalid fields.
  @JsonKey(name: r'details', required: false, includeIfNull: false)
  final Map<String, Object>? details;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ErrorBody &&
            runtimeType == other.runtimeType &&
            equals(
              [code, message, details],
              [other.code, other.message, other.details],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([code, message, details]);

  factory ErrorBody.fromJson(Map<String, dynamic> json) =>
      _$ErrorBodyFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorBodyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
