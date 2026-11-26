//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/delivery_pattern.dart';
import 'package:pao_api/src/model/subscription_status.dart';
import 'package:pao_api/src/model/quantity_unit.dart';
import 'package:pao_api/src/model/booking_address.dart';
import 'package:pao_api/src/model/delivery_date.dart';
import 'package:pao_api/src/model/delivery_window.dart';
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/booking_party.dart';
import 'package:pao_api/src/model/booking_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'subscription.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Subscription {
  /// Returns a new [Subscription] instance.
  Subscription({
    required this.id,

    required this.number,

    required this.status,

    required this.serviceId,

    required this.serviceName,

    this.provider,

    this.customer,

    required this.items,

    required this.total,

    this.unit,

    required this.pattern,

    this.weekdays,

    this.dayOfMonth,

    required this.window,

    required this.startDate,

    this.endDate,

    this.count,

    required this.address,

    this.note,

    required this.createdAt,

    this.upcoming,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'number', required: true, includeIfNull: false)
  final String number;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final SubscriptionStatus status;

  @JsonKey(name: r'serviceId', required: true, includeIfNull: false)
  final String serviceId;

  @JsonKey(name: r'serviceName', required: true, includeIfNull: false)
  final LocalizedText serviceName;

  @JsonKey(name: r'provider', required: false, includeIfNull: false)
  final BookingParty? provider;

  @JsonKey(name: r'customer', required: false, includeIfNull: false)
  final BookingParty? customer;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItem> items;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'unit', required: false, includeIfNull: false)
  final QuantityUnit? unit;

  @JsonKey(name: r'pattern', required: true, includeIfNull: false)
  final DeliveryPattern pattern;

  @JsonKey(name: r'weekdays', required: false, includeIfNull: false)
  final List<int>? weekdays;

  @JsonKey(name: r'dayOfMonth', required: false, includeIfNull: false)
  final int? dayOfMonth;

  @JsonKey(name: r'window', required: true, includeIfNull: false)
  final DeliveryWindow window;

  @JsonKey(name: r'startDate', required: true, includeIfNull: false)
  final String startDate;

  @JsonKey(name: r'endDate', required: false, includeIfNull: false)
  final String? endDate;

  @JsonKey(name: r'count', required: false, includeIfNull: false)
  final int? count;

  @JsonKey(name: r'address', required: true, includeIfNull: false)
  final BookingAddress address;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  /// The next dates, up to 31 days ahead.
  @JsonKey(name: r'upcoming', required: false, includeIfNull: false)
  final List<DeliveryDate>? upcoming;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Subscription &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                number,
                status,
                serviceId,
                serviceName,
                provider,
                customer,
                items,
                total,
                unit,
                pattern,
                weekdays,
                dayOfMonth,
                window,
                startDate,
                endDate,
                count,
                address,
                note,
                createdAt,
                upcoming,
              ],
              [
                other.id,
                other.number,
                other.status,
                other.serviceId,
                other.serviceName,
                other.provider,
                other.customer,
                other.items,
                other.total,
                other.unit,
                other.pattern,
                other.weekdays,
                other.dayOfMonth,
                other.window,
                other.startDate,
                other.endDate,
                other.count,
                other.address,
                other.note,
                other.createdAt,
                other.upcoming,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        number,
        status,
        serviceId,
        serviceName,
        provider,
        customer,
        items,
        total,
        unit,
        pattern,
        weekdays,
        dayOfMonth,
        window,
        startDate,
        endDate,
        count,
        address,
        note,
        createdAt,
        upcoming,
      ]);

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
