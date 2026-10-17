//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'complaint_resolve_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComplaintResolveInput {
  /// Returns a new [ComplaintResolveInput] instance.
  ComplaintResolveInput({required this.resolution, required this.verified});

  @JsonKey(name: r'resolution', required: true, includeIfNull: false)
  final String resolution;

  @JsonKey(name: r'verified', required: true, includeIfNull: false)
  final bool verified;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ComplaintResolveInput &&
            runtimeType == other.runtimeType &&
            equals([resolution, verified], [other.resolution, other.verified]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([resolution, verified]);

  factory ComplaintResolveInput.fromJson(Map<String, dynamic> json) =>
      _$ComplaintResolveInputFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintResolveInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
