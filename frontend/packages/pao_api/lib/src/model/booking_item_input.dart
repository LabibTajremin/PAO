//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'booking_item_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BookingItemInput {
  /// Returns a new [BookingItemInput] instance.
  BookingItemInput({required this.subServiceId, required this.quantity});

  @JsonKey(name: r'subServiceId', required: true, includeIfNull: false)
  final String subServiceId;

  // minimum: 1
  // maximum: 50
  @JsonKey(name: r'quantity', required: true, includeIfNull: false)
  final int quantity;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BookingItemInput &&
            runtimeType == other.runtimeType &&
            equals(
              [subServiceId, quantity],
              [other.subServiceId, other.quantity],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([subServiceId, quantity]);

  factory BookingItemInput.fromJson(Map<String, dynamic> json) =>
      _$BookingItemInputFromJson(json);

  Map<String, dynamic> toJson() => _$BookingItemInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
