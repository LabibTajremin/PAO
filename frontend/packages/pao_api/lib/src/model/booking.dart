//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_address.dart';
import 'package:pao_api/src/model/booking_status.dart';
import 'package:pao_api/src/model/extras_proposal.dart';
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/timing.dart';
import 'package:pao_api/src/model/timeline_entry.dart';
import 'package:pao_api/src/model/booking_party.dart';
import 'package:pao_api/src/model/service_model.dart';
import 'package:pao_api/src/model/booking_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'booking.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Booking {
  /// Returns a new [Booking] instance.
  Booking({
    required this.id,

    required this.number,

    required this.status,

    required this.serviceId,

    required this.serviceName,

    this.serviceModel,

    this.provider,

    this.customer,

    required this.items,

    required this.total,

    required this.timing,

    this.scheduledAt,

    this.endsAt,

    required this.address,

    this.note,

    this.acceptDeadline,

    this.pendingExtras,

    this.cancellable,

    required this.paymentMethod,

    this.cashReceived,

    this.reviewedByMe,

    required this.createdAt,

    required this.timeline,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'number', required: true, includeIfNull: false)
  final String number;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final BookingStatus status;

  @JsonKey(name: r'serviceId', required: true, includeIfNull: false)
  final String serviceId;

  @JsonKey(name: r'serviceName', required: true, includeIfNull: false)
  final LocalizedText serviceName;

  @JsonKey(name: r'serviceModel', required: false, includeIfNull: false)
  final ServiceModel? serviceModel;

  @JsonKey(name: r'provider', required: false, includeIfNull: false)
  final BookingParty? provider;

  @JsonKey(name: r'customer', required: false, includeIfNull: false)
  final BookingParty? customer;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItem> items;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'timing', required: true, includeIfNull: false)
  final Timing timing;

  @JsonKey(name: r'scheduledAt', required: false, includeIfNull: false)
  final DateTime? scheduledAt;

  /// End of a duration hire.
  @JsonKey(name: r'endsAt', required: false, includeIfNull: false)
  final DateTime? endsAt;

  @JsonKey(name: r'address', required: true, includeIfNull: false)
  final BookingAddress address;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  @JsonKey(name: r'acceptDeadline', required: false, includeIfNull: false)
  final DateTime? acceptDeadline;

  @JsonKey(name: r'pendingExtras', required: false, includeIfNull: false)
  final ExtrasProposal? pendingExtras;

  @JsonKey(name: r'cancellable', required: false, includeIfNull: false)
  final bool? cancellable;

  @JsonKey(name: r'paymentMethod', required: true, includeIfNull: false)
  final BookingPaymentMethodEnum paymentMethod;

  @JsonKey(name: r'cashReceived', required: false, includeIfNull: false)
  final bool? cashReceived;

  @JsonKey(name: r'reviewedByMe', required: false, includeIfNull: false)
  final bool? reviewedByMe;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'timeline', required: true, includeIfNull: false)
  final List<TimelineEntry> timeline;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Booking &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                number,
                status,
                serviceId,
                serviceName,
                serviceModel,
                provider,
                customer,
                items,
                total,
                timing,
                scheduledAt,
                endsAt,
                address,
                note,
                acceptDeadline,
                pendingExtras,
                cancellable,
                paymentMethod,
                cashReceived,
                reviewedByMe,
                createdAt,
                timeline,
              ],
              [
                other.id,
                other.number,
                other.status,
                other.serviceId,
                other.serviceName,
                other.serviceModel,
                other.provider,
                other.customer,
                other.items,
                other.total,
                other.timing,
                other.scheduledAt,
                other.endsAt,
                other.address,
                other.note,
                other.acceptDeadline,
                other.pendingExtras,
                other.cancellable,
                other.paymentMethod,
                other.cashReceived,
                other.reviewedByMe,
                other.createdAt,
                other.timeline,
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
        serviceModel,
        provider,
        customer,
        items,
        total,
        timing,
        scheduledAt,
        endsAt,
        address,
        note,
        acceptDeadline,
        pendingExtras,
        cancellable,
        paymentMethod,
        cashReceived,
        reviewedByMe,
        createdAt,
        timeline,
      ]);

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum BookingPaymentMethodEnum {
  @JsonValue(r'cash')
  cash(r'cash');

  const BookingPaymentMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
