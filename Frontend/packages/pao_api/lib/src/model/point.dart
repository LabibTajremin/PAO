//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'point.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Point {
  /// Returns a new [Point] instance.
  Point({required this.lat, required this.lng});

  // minimum: -90
  // maximum: 90
  @JsonKey(name: r'lat', required: true, includeIfNull: false)
  final double lat;

  // minimum: -180
  // maximum: 180
  @JsonKey(name: r'lng', required: true, includeIfNull: false)
  final double lng;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Point &&
            runtimeType == other.runtimeType &&
            equals([lat, lng], [other.lat, other.lng]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([lat, lng]);

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);

  Map<String, dynamic> toJson() => _$PointToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
