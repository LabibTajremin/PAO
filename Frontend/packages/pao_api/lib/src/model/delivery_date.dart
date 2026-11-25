//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_item_input.dart';
import 'package:pao_api/src/model/delivery_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'delivery_date.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeliveryDate {
  /// Returns a new [DeliveryDate] instance.
  DeliveryDate({
    required this.date,

    required this.status,

    required this.items,

    required this.total,

    this.bookingId,

    this.changeable,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final String date;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final DeliveryStatus status;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItemInput> items;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  /// The booking the delivery became.
  @JsonKey(name: r'bookingId', required: false, includeIfNull: false)
  final String? bookingId;

  /// Whether the date's cutoff has not passed yet.
  @JsonKey(name: r'changeable', required: false, includeIfNull: false)
  final bool? changeable;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeliveryDate &&
            runtimeType == other.runtimeType &&
            equals(
              [date, status, items, total, bookingId, changeable],
              [
                other.date,
                other.status,
                other.items,
                other.total,
                other.bookingId,
                other.changeable,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([date, status, items, total, bookingId, changeable]);

  factory DeliveryDate.fromJson(Map<String, dynamic> json) =>
      _$DeliveryDateFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryDateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
