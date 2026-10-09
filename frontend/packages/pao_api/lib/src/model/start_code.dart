//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'start_code.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StartCode {
  /// Returns a new [StartCode] instance.
  StartCode({required this.code});

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StartCode &&
            runtimeType == other.runtimeType &&
            equals([code], [other.code]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([code]);

  factory StartCode.fromJson(Map<String, dynamic> json) =>
      _$StartCodeFromJson(json);

  Map<String, dynamic> toJson() => _$StartCodeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
