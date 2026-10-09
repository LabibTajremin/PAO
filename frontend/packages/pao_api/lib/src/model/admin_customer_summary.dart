//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/account_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_customer_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCustomerSummary {
  /// Returns a new [AdminCustomerSummary] instance.
  AdminCustomerSummary({
    required this.id,

    required this.name,

    this.phone,

    required this.status,

    required this.bookings,

    this.rating,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AccountStatus status;

  @JsonKey(name: r'bookings', required: true, includeIfNull: false)
  final int bookings;

  @JsonKey(name: r'rating', required: false, includeIfNull: false)
  final double? rating;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminCustomerSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [id, name, phone, status, bookings, rating, createdAt],
              [
                other.id,
                other.name,
                other.phone,
                other.status,
                other.bookings,
                other.rating,
                other.createdAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        name,
        phone,
        status,
        bookings,
        rating,
        createdAt,
      ]);

  factory AdminCustomerSummary.fromJson(Map<String, dynamic> json) =>
      _$AdminCustomerSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCustomerSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
