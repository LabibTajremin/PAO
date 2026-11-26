//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'delivery_change.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeliveryChange {
  /// Returns a new [DeliveryChange] instance.
  DeliveryChange({this.skip, this.items});

  @JsonKey(name: r'skip', required: false, includeIfNull: false)
  final bool? skip;

  @JsonKey(name: r'items', required: false, includeIfNull: false)
  final List<BookingItemInput>? items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeliveryChange &&
            runtimeType == other.runtimeType &&
            equals([skip, items], [other.skip, other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([skip, items]);

  factory DeliveryChange.fromJson(Map<String, dynamic> json) =>
      _$DeliveryChangeFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryChangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
