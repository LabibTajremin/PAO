//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'service_area_check.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServiceAreaCheck {
  /// Returns a new [ServiceAreaCheck] instance.
  ServiceAreaCheck({required this.covered, this.areaName});

  @JsonKey(name: r'covered', required: true, includeIfNull: false)
  final bool covered;

  @JsonKey(name: r'areaName', required: false, includeIfNull: false)
  final String? areaName;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceAreaCheck &&
            runtimeType == other.runtimeType &&
            equals([covered, areaName], [other.covered, other.areaName]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([covered, areaName]);

  factory ServiceAreaCheck.fromJson(Map<String, dynamic> json) =>
      _$ServiceAreaCheckFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceAreaCheckToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
