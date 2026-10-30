//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/point.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'service_area_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServiceAreaInput {
  /// Returns a new [ServiceAreaInput] instance.
  ServiceAreaInput({required this.homeBase, required this.workingRadiusM});

  @JsonKey(name: r'homeBase', required: true, includeIfNull: false)
  final Point homeBase;

  // minimum: 1000
  // maximum: 30000
  @JsonKey(name: r'workingRadiusM', required: true, includeIfNull: false)
  final int workingRadiusM;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceAreaInput &&
            runtimeType == other.runtimeType &&
            equals(
              [homeBase, workingRadiusM],
              [other.homeBase, other.workingRadiusM],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([homeBase, workingRadiusM]);

  factory ServiceAreaInput.fromJson(Map<String, dynamic> json) =>
      _$ServiceAreaInputFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceAreaInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
