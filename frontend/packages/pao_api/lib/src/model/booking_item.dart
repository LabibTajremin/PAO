//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/price_unit.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'booking_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BookingItem {
  /// Returns a new [BookingItem] instance.
  BookingItem({
    required this.subServiceId,

    required this.priceVersionId,

    required this.name,

    required this.unit,

    required this.quantity,

    required this.unitPrice,

    required this.total,

    required this.extra,
  });

  @JsonKey(name: r'subServiceId', required: true, includeIfNull: false)
  final String subServiceId;

  @JsonKey(name: r'priceVersionId', required: true, includeIfNull: false)
  final String priceVersionId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final LocalizedText name;

  @JsonKey(name: r'unit', required: true, includeIfNull: false)
  final PriceUnit unit;

  @JsonKey(name: r'quantity', required: true, includeIfNull: false)
  final int quantity;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'unitPrice', required: true, includeIfNull: false)
  final int unitPrice;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  /// Added during the job and approved by the customer.
  @JsonKey(name: r'extra', required: true, includeIfNull: false)
  final bool extra;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BookingItem &&
            runtimeType == other.runtimeType &&
            equals(
              [
                subServiceId,
                priceVersionId,
                name,
                unit,
                quantity,
                unitPrice,
                total,
                extra,
              ],
              [
                other.subServiceId,
                other.priceVersionId,
                other.name,
                other.unit,
                other.quantity,
                other.unitPrice,
                other.total,
                other.extra,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        subServiceId,
        priceVersionId,
        name,
        unit,
        quantity,
        unitPrice,
        total,
        extra,
      ]);

  factory BookingItem.fromJson(Map<String, dynamic> json) =>
      _$BookingItemFromJson(json);

  Map<String, dynamic> toJson() => _$BookingItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
