//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'extras_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExtrasInput {
  /// Returns a new [ExtrasInput] instance.
  ExtrasInput({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItemInput> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExtrasInput &&
            runtimeType == other.runtimeType &&
            equals([items], [other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items]);

  factory ExtrasInput.fromJson(Map<String, dynamic> json) =>
      _$ExtrasInputFromJson(json);

  Map<String, dynamic> toJson() => _$ExtrasInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
