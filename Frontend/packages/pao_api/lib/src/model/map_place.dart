//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/point.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'map_place.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MapPlace {
  /// Returns a new [MapPlace] instance.
  MapPlace({
    required this.id,

    required this.kind,

    required this.title,

    this.area,

    required this.location,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final MapPlaceKindEnum kind;

  /// The name in the caller's language when OSM has one.
  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  /// The neighbourhood; absent when none is known.
  @JsonKey(name: r'area', required: false, includeIfNull: false)
  final String? area;

  @JsonKey(name: r'location', required: true, includeIfNull: false)
  final Point location;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MapPlace &&
            runtimeType == other.runtimeType &&
            equals(
              [id, kind, title, area, location],
              [other.id, other.kind, other.title, other.area, other.location],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, kind, title, area, location]);

  factory MapPlace.fromJson(Map<String, dynamic> json) =>
      _$MapPlaceFromJson(json);

  Map<String, dynamic> toJson() => _$MapPlaceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MapPlaceKindEnum {
  @JsonValue(r'area')
  area(r'area'),
  @JsonValue(r'street')
  street(r'street'),
  @JsonValue(r'place')
  place(r'place'),
  @JsonValue(r'address')
  address(r'address');

  const MapPlaceKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
