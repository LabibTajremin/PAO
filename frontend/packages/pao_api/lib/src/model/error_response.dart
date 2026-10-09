//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/error_body.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'error_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ErrorResponse {
  /// Returns a new [ErrorResponse] instance.
  ErrorResponse({required this.error});

  @JsonKey(name: r'error', required: true, includeIfNull: false)
  final ErrorBody error;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ErrorResponse &&
            runtimeType == other.runtimeType &&
            equals([error], [other.error]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([error]);

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
