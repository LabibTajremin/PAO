//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'services_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServicesInput {
  /// Returns a new [ServicesInput] instance.
  ServicesInput({required this.serviceIds, required this.experienceYears});

  @JsonKey(name: r'serviceIds', required: true, includeIfNull: false)
  final List<String> serviceIds;

  // minimum: 0
  // maximum: 60
  @JsonKey(name: r'experienceYears', required: true, includeIfNull: false)
  final int experienceYears;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServicesInput &&
            runtimeType == other.runtimeType &&
            equals(
              [serviceIds, experienceYears],
              [other.serviceIds, other.experienceYears],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([serviceIds, experienceYears]);

  factory ServicesInput.fromJson(Map<String, dynamic> json) =>
      _$ServicesInputFromJson(json);

  Map<String, dynamic> toJson() => _$ServicesInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
