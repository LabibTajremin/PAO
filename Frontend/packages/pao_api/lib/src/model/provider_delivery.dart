//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_address.dart';
import 'package:pao_api/src/model/delivery_window.dart';
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/booking_item_input.dart';
import 'package:pao_api/src/model/delivery_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'provider_delivery.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderDelivery {
  /// Returns a new [ProviderDelivery] instance.
  ProviderDelivery({
    required this.subscriptionId,

    required this.number,

    required this.date,

    required this.window,

    required this.status,

    required this.serviceName,

    required this.items,

    required this.total,

    required this.address,

    this.customerName,

    this.bookingId,
  });

  @JsonKey(name: r'subscriptionId', required: true, includeIfNull: false)
  final String subscriptionId;

  @JsonKey(name: r'number', required: true, includeIfNull: false)
  final String number;

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final String date;

  @JsonKey(name: r'window', required: true, includeIfNull: false)
  final DeliveryWindow window;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final DeliveryStatus status;

  @JsonKey(name: r'serviceName', required: true, includeIfNull: false)
  final LocalizedText serviceName;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItemInput> items;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'address', required: true, includeIfNull: false)
  final BookingAddress address;

  @JsonKey(name: r'customerName', required: false, includeIfNull: false)
  final String? customerName;

  @JsonKey(name: r'bookingId', required: false, includeIfNull: false)
  final String? bookingId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProviderDelivery &&
            runtimeType == other.runtimeType &&
            equals(
              [
                subscriptionId,
                number,
                date,
                window,
                status,
                serviceName,
                items,
                total,
                address,
                customerName,
                bookingId,
              ],
              [
                other.subscriptionId,
                other.number,
                other.date,
                other.window,
                other.status,
                other.serviceName,
                other.items,
                other.total,
                other.address,
                other.customerName,
                other.bookingId,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        subscriptionId,
        number,
        date,
        window,
        status,
        serviceName,
        items,
        total,
        address,
        customerName,
        bookingId,
      ]);

  factory ProviderDelivery.fromJson(Map<String, dynamic> json) =>
      _$ProviderDeliveryFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderDeliveryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
