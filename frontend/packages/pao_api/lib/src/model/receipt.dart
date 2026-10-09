//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/booking_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'receipt.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Receipt {
  /// Returns a new [Receipt] instance.
  Receipt({
    required this.bookingId,

    required this.number,

    required this.completedAt,

    required this.serviceName,

    required this.providerName,

    required this.customerName,

    this.area,

    required this.items,

    required this.total,

    required this.paymentMethod,
  });

  @JsonKey(name: r'bookingId', required: true, includeIfNull: false)
  final String bookingId;

  @JsonKey(name: r'number', required: true, includeIfNull: false)
  final String number;

  @JsonKey(name: r'completedAt', required: true, includeIfNull: false)
  final DateTime completedAt;

  @JsonKey(name: r'serviceName', required: true, includeIfNull: false)
  final LocalizedText serviceName;

  @JsonKey(name: r'providerName', required: true, includeIfNull: false)
  final String providerName;

  @JsonKey(name: r'customerName', required: true, includeIfNull: false)
  final String customerName;

  @JsonKey(name: r'area', required: false, includeIfNull: false)
  final String? area;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItem> items;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'paymentMethod', required: true, includeIfNull: false)
  final ReceiptPaymentMethodEnum paymentMethod;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Receipt &&
            runtimeType == other.runtimeType &&
            equals(
              [
                bookingId,
                number,
                completedAt,
                serviceName,
                providerName,
                customerName,
                area,
                items,
                total,
                paymentMethod,
              ],
              [
                other.bookingId,
                other.number,
                other.completedAt,
                other.serviceName,
                other.providerName,
                other.customerName,
                other.area,
                other.items,
                other.total,
                other.paymentMethod,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        bookingId,
        number,
        completedAt,
        serviceName,
        providerName,
        customerName,
        area,
        items,
        total,
        paymentMethod,
      ]);

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ReceiptPaymentMethodEnum {
  @JsonValue(r'cash')
  cash(r'cash');

  const ReceiptPaymentMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
