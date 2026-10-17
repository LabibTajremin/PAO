//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/address_label.dart';
import 'package:pao_api/src/model/point.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'address_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddressInput {
  /// Returns a new [AddressInput] instance.
  AddressInput({
    required this.label,

    required this.line1,

    this.line2,

    this.area,

    required this.location,

    this.isDefault,
  });

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final AddressLabel label;

  @JsonKey(name: r'line1', required: true, includeIfNull: false)
  final String line1;

  @JsonKey(name: r'line2', required: false, includeIfNull: false)
  final String? line2;

  @JsonKey(name: r'area', required: false, includeIfNull: false)
  final String? area;

  @JsonKey(name: r'location', required: true, includeIfNull: false)
  final Point location;

  @JsonKey(name: r'isDefault', required: false, includeIfNull: false)
  final bool? isDefault;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AddressInput &&
            runtimeType == other.runtimeType &&
            equals(
              [label, line1, line2, area, location, isDefault],
              [
                other.label,
                other.line1,
                other.line2,
                other.area,
                other.location,
                other.isDefault,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([label, line1, line2, area, location, isDefault]);

  factory AddressInput.fromJson(Map<String, dynamic> json) =>
      _$AddressInputFromJson(json);

  Map<String, dynamic> toJson() => _$AddressInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
