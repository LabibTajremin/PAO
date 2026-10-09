//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/point.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'booking_address.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BookingAddress {
  /// Returns a new [BookingAddress] instance.
  BookingAddress({
    required this.area,

    this.line1,

    this.line2,

    this.location,

    this.distanceM,
  });

  @JsonKey(name: r'area', required: true, includeIfNull: false)
  final String area;

  @JsonKey(name: r'line1', required: false, includeIfNull: false)
  final String? line1;

  @JsonKey(name: r'line2', required: false, includeIfNull: false)
  final String? line2;

  @JsonKey(name: r'location', required: false, includeIfNull: false)
  final Point? location;

  /// Provider view before acceptance.
  @JsonKey(name: r'distanceM', required: false, includeIfNull: false)
  final int? distanceM;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BookingAddress &&
            runtimeType == other.runtimeType &&
            equals(
              [area, line1, line2, location, distanceM],
              [
                other.area,
                other.line1,
                other.line2,
                other.location,
                other.distanceM,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([area, line1, line2, location, distanceM]);

  factory BookingAddress.fromJson(Map<String, dynamic> json) =>
      _$BookingAddressFromJson(json);

  Map<String, dynamic> toJson() => _$BookingAddressToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
