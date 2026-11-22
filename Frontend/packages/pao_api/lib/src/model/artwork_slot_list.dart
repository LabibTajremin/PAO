//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/artwork_slot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'artwork_slot_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ArtworkSlotList {
  /// Returns a new [ArtworkSlotList] instance.
  ArtworkSlotList({required this.slots});

  @JsonKey(name: r'slots', required: true, includeIfNull: false)
  final List<ArtworkSlot> slots;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ArtworkSlotList &&
            runtimeType == other.runtimeType &&
            equals([slots], [other.slots]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([slots]);

  factory ArtworkSlotList.fromJson(Map<String, dynamic> json) =>
      _$ArtworkSlotListFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkSlotListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
