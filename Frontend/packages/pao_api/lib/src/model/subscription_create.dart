//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/delivery_pattern.dart';
import 'package:pao_api/src/model/delivery_window.dart';
import 'package:pao_api/src/model/booking_item_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'subscription_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionCreate {
  /// Returns a new [SubscriptionCreate] instance.
  SubscriptionCreate({
    required this.providerId,

    required this.serviceId,

    required this.items,

    required this.addressId,

    required this.pattern,

    this.weekdays,

    this.dayOfMonth,

    required this.window,

    required this.startDate,

    this.endDate,

    this.count,

    this.note,
  });

  @JsonKey(name: r'providerId', required: true, includeIfNull: false)
  final String providerId;

  @JsonKey(name: r'serviceId', required: true, includeIfNull: false)
  final String serviceId;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItemInput> items;

  @JsonKey(name: r'addressId', required: true, includeIfNull: false)
  final String addressId;

  @JsonKey(name: r'pattern', required: true, includeIfNull: false)
  final DeliveryPattern pattern;

  /// 0 is Sunday and 5 is Friday.
  @JsonKey(name: r'weekdays', required: false, includeIfNull: false)
  final Set<int>? weekdays;

  // minimum: 1
  // maximum: 31
  @JsonKey(name: r'dayOfMonth', required: false, includeIfNull: false)
  final int? dayOfMonth;

  @JsonKey(name: r'window', required: true, includeIfNull: false)
  final DeliveryWindow window;

  @JsonKey(name: r'startDate', required: true, includeIfNull: false)
  final String startDate;

  /// The last date; leave out with count for an open subscription.
  @JsonKey(name: r'endDate', required: false, includeIfNull: false)
  final String? endDate;

  /// How many deliveries, instead of an end date.
  // minimum: 1
  // maximum: 366
  @JsonKey(name: r'count', required: false, includeIfNull: false)
  final int? count;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubscriptionCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [
                providerId,
                serviceId,
                items,
                addressId,
                pattern,
                weekdays,
                dayOfMonth,
                window,
                startDate,
                endDate,
                count,
                note,
              ],
              [
                other.providerId,
                other.serviceId,
                other.items,
                other.addressId,
                other.pattern,
                other.weekdays,
                other.dayOfMonth,
                other.window,
                other.startDate,
                other.endDate,
                other.count,
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
        addressId,
        pattern,
        weekdays,
        dayOfMonth,
        window,
        startDate,
        endDate,
        count,
        note,
      ]);

  factory SubscriptionCreate.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionCreateFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
