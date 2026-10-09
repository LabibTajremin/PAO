//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/timing.dart';
import 'package:pao_api/src/model/booking_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'booking_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BookingCreate {
  /// Returns a new [BookingCreate] instance.
  BookingCreate({
    required this.providerId,

    required this.serviceId,

    required this.items,

    required this.timing,

    this.scheduledAt,

    required this.addressId,

    this.note,
  });

  @JsonKey(name: r'providerId', required: true, includeIfNull: false)
  final String providerId;

  @JsonKey(name: r'serviceId', required: true, includeIfNull: false)
  final String serviceId;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItemInput> items;

  @JsonKey(name: r'timing', required: true, includeIfNull: false)
  final Timing timing;

  /// Required when timing is scheduled; for duration hire it is the start.
  @JsonKey(name: r'scheduledAt', required: false, includeIfNull: false)
  final DateTime? scheduledAt;

  @JsonKey(name: r'addressId', required: true, includeIfNull: false)
  final String addressId;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BookingCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [
                providerId,
                serviceId,
                items,
                timing,
                scheduledAt,
                addressId,
                note,
              ],
              [
                other.providerId,
                other.serviceId,
                other.items,
                other.timing,
                other.scheduledAt,
                other.addressId,
                other.note,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        providerId,
        serviceId,
        items,
        timing,
        scheduledAt,
        addressId,
        note,
      ]);

  factory BookingCreate.fromJson(Map<String, dynamic> json) =>
      _$BookingCreateFromJson(json);

  Map<String, dynamic> toJson() => _$BookingCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
