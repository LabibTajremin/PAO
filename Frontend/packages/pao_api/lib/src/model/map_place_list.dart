//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/map_place.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'map_place_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MapPlaceList {
  /// Returns a new [MapPlaceList] instance.
  MapPlaceList({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<MapPlace> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MapPlaceList &&
            runtimeType == other.runtimeType &&
            equals([items], [other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items]);

  factory MapPlaceList.fromJson(Map<String, dynamic> json) =>
      _$MapPlaceListFromJson(json);

  Map<String, dynamic> toJson() => _$MapPlaceListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
