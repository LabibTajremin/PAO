// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingCWProxy {
  Booking id(String id);

  Booking number(String number);

  Booking status(BookingStatus status);

  Booking serviceId(String serviceId);

  Booking serviceName(LocalizedText serviceName);

  Booking serviceModel(ServiceModel? serviceModel);

  Booking provider(BookingParty? provider);

  Booking customer(BookingParty? customer);

  Booking items(List<BookingItem> items);

  Booking total(int total);

  Booking timing(Timing timing);

  Booking scheduledAt(DateTime? scheduledAt);

  Booking endsAt(DateTime? endsAt);

  Booking address(BookingAddress address);

  Booking note(String? note);

  Booking acceptDeadline(DateTime? acceptDeadline);

  Booking pendingExtras(ExtrasProposal? pendingExtras);

  Booking cancellable(bool? cancellable);

  Booking paymentMethod(BookingPaymentMethodEnum paymentMethod);

  Booking cashReceived(bool? cashReceived);

  Booking reviewedByMe(bool? reviewedByMe);

  Booking createdAt(DateTime createdAt);

  Booking timeline(List<TimelineEntry> timeline);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Booking(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Booking(...).copyWith(id: 12, name: "My name")
  /// ```
  Booking call({
    String id,
    String number,
    BookingStatus status,
    String serviceId,
    LocalizedText serviceName,
    ServiceModel? serviceModel,
    BookingParty? provider,
    BookingParty? customer,
    List<BookingItem> items,
    int total,
    Timing timing,
    DateTime? scheduledAt,
    DateTime? endsAt,
    BookingAddress address,
    String? note,
    DateTime? acceptDeadline,
    ExtrasProposal? pendingExtras,
    bool? cancellable,
    BookingPaymentMethodEnum paymentMethod,
    bool? cashReceived,
    bool? reviewedByMe,
    DateTime createdAt,
    List<TimelineEntry> timeline,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBooking.copyWith(...)` or call `instanceOfBooking.copyWith.fieldName(value)` for a single field.
class _$BookingCWProxyImpl implements _$BookingCWProxy {
  const _$BookingCWProxyImpl(this._value);

  final Booking _value;

  @override
  Booking id(String id) => call(id: id);

  @override
  Booking number(String number) => call(number: number);

  @override
  Booking status(BookingStatus status) => call(status: status);

  @override
  Booking serviceId(String serviceId) => call(serviceId: serviceId);

  @override
  Booking serviceName(LocalizedText serviceName) =>
      call(serviceName: serviceName);

  @override
  Booking serviceModel(ServiceModel? serviceModel) =>
      call(serviceModel: serviceModel);

  @override
  Booking provider(BookingParty? provider) => call(provider: provider);

  @override
  Booking customer(BookingParty? customer) => call(customer: customer);

  @override
  Booking items(List<BookingItem> items) => call(items: items);

  @override
  Booking total(int total) => call(total: total);

  @override
  Booking timing(Timing timing) => call(timing: timing);

  @override
  Booking scheduledAt(DateTime? scheduledAt) => call(scheduledAt: scheduledAt);

  @override
  Booking endsAt(DateTime? endsAt) => call(endsAt: endsAt);

  @override
  Booking address(BookingAddress address) => call(address: address);

  @override
  Booking note(String? note) => call(note: note);

  @override
  Booking acceptDeadline(DateTime? acceptDeadline) =>
      call(acceptDeadline: acceptDeadline);

  @override
  Booking pendingExtras(ExtrasProposal? pendingExtras) =>
      call(pendingExtras: pendingExtras);

  @override
  Booking cancellable(bool? cancellable) => call(cancellable: cancellable);

  @override
  Booking paymentMethod(BookingPaymentMethodEnum paymentMethod) =>
      call(paymentMethod: paymentMethod);

  @override
  Booking cashReceived(bool? cashReceived) => call(cashReceived: cashReceived);

  @override
  Booking reviewedByMe(bool? reviewedByMe) => call(reviewedByMe: reviewedByMe);

  @override
  Booking createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  Booking timeline(List<TimelineEntry> timeline) => call(timeline: timeline);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Booking(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Booking(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Booking call({
    Object? id = const $CopyWithPlaceholder(),
    Object? number = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? serviceName = const $CopyWithPlaceholder(),
    Object? serviceModel = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? customer = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? timing = const $CopyWithPlaceholder(),
    Object? scheduledAt = const $CopyWithPlaceholder(),
    Object? endsAt = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? acceptDeadline = const $CopyWithPlaceholder(),
    Object? pendingExtras = const $CopyWithPlaceholder(),
    Object? cancellable = const $CopyWithPlaceholder(),
    Object? paymentMethod = const $CopyWithPlaceholder(),
    Object? cashReceived = const $CopyWithPlaceholder(),
    Object? reviewedByMe = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? timeline = const $CopyWithPlaceholder(),
  }) {
    return Booking(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      number: number == const $CopyWithPlaceholder() || number == null
          ? _value.number
          // ignore: cast_nullable_to_non_nullable
          : number as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as BookingStatus,
      serviceId: serviceId == const $CopyWithPlaceholder() || serviceId == null
          ? _value.serviceId
          // ignore: cast_nullable_to_non_nullable
          : serviceId as String,
      serviceName:
          serviceName == const $CopyWithPlaceholder() || serviceName == null
          ? _value.serviceName
          // ignore: cast_nullable_to_non_nullable
          : serviceName as LocalizedText,
      serviceModel: serviceModel == const $CopyWithPlaceholder()
          ? _value.serviceModel
          // ignore: cast_nullable_to_non_nullable
          : serviceModel as ServiceModel?,
      provider: provider == const $CopyWithPlaceholder()
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as BookingParty?,
      customer: customer == const $CopyWithPlaceholder()
          ? _value.customer
          // ignore: cast_nullable_to_non_nullable
          : customer as BookingParty?,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItem>,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      timing: timing == const $CopyWithPlaceholder() || timing == null
          ? _value.timing
          // ignore: cast_nullable_to_non_nullable
          : timing as Timing,
      scheduledAt: scheduledAt == const $CopyWithPlaceholder()
          ? _value.scheduledAt
          // ignore: cast_nullable_to_non_nullable
          : scheduledAt as DateTime?,
      endsAt: endsAt == const $CopyWithPlaceholder()
          ? _value.endsAt
          // ignore: cast_nullable_to_non_nullable
          : endsAt as DateTime?,
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as BookingAddress,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      acceptDeadline: acceptDeadline == const $CopyWithPlaceholder()
          ? _value.acceptDeadline
          // ignore: cast_nullable_to_non_nullable
          : acceptDeadline as DateTime?,
      pendingExtras: pendingExtras == const $CopyWithPlaceholder()
          ? _value.pendingExtras
          // ignore: cast_nullable_to_non_nullable
          : pendingExtras as ExtrasProposal?,
      cancellable: cancellable == const $CopyWithPlaceholder()
          ? _value.cancellable
          // ignore: cast_nullable_to_non_nullable
          : cancellable as bool?,
      paymentMethod:
          paymentMethod == const $CopyWithPlaceholder() || paymentMethod == null
          ? _value.paymentMethod
          // ignore: cast_nullable_to_non_nullable
          : paymentMethod as BookingPaymentMethodEnum,
      cashReceived: cashReceived == const $CopyWithPlaceholder()
          ? _value.cashReceived
          // ignore: cast_nullable_to_non_nullable
          : cashReceived as bool?,
      reviewedByMe: reviewedByMe == const $CopyWithPlaceholder()
          ? _value.reviewedByMe
          // ignore: cast_nullable_to_non_nullable
          : reviewedByMe as bool?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      timeline: timeline == const $CopyWithPlaceholder() || timeline == null
          ? _value.timeline
          // ignore: cast_nullable_to_non_nullable
          : timeline as List<TimelineEntry>,
    );
  }
}

extension $BookingCopyWith on Booking {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBooking.copyWith(...)` or `instanceOfBooking.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingCWProxy get copyWith => _$BookingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Booking', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'number',
      'status',
      'serviceId',
      'serviceName',
      'items',
      'total',
      'timing',
      'address',
      'paymentMethod',
      'createdAt',
      'timeline',
    ],
  );
  final val = Booking(
    id: $checkedConvert('id', (v) => v as String),
    number: $checkedConvert('number', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$BookingStatusEnumMap, v),
    ),
    serviceId: $checkedConvert('serviceId', (v) => v as String),
    serviceName: $checkedConvert(
      'serviceName',
      (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
    ),
    serviceModel: $checkedConvert(
      'serviceModel',
      (v) => $enumDecodeNullable(_$ServiceModelEnumMap, v),
    ),
    provider: $checkedConvert(
      'provider',
      (v) =>
          v == null ? null : BookingParty.fromJson(v as Map<String, dynamic>),
    ),
    customer: $checkedConvert(
      'customer',
      (v) =>
          v == null ? null : BookingParty.fromJson(v as Map<String, dynamic>),
    ),
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => BookingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    total: $checkedConvert('total', (v) => (v as num).toInt()),
    timing: $checkedConvert('timing', (v) => $enumDecode(_$TimingEnumMap, v)),
    scheduledAt: $checkedConvert(
      'scheduledAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    endsAt: $checkedConvert(
      'endsAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    address: $checkedConvert(
      'address',
      (v) => BookingAddress.fromJson(v as Map<String, dynamic>),
    ),
    note: $checkedConvert('note', (v) => v as String?),
    acceptDeadline: $checkedConvert(
      'acceptDeadline',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    pendingExtras: $checkedConvert(
      'pendingExtras',
      (v) =>
          v == null ? null : ExtrasProposal.fromJson(v as Map<String, dynamic>),
    ),
    cancellable: $checkedConvert('cancellable', (v) => v as bool?),
    paymentMethod: $checkedConvert(
      'paymentMethod',
      (v) => $enumDecode(_$BookingPaymentMethodEnumEnumMap, v),
    ),
    cashReceived: $checkedConvert('cashReceived', (v) => v as bool?),
    reviewedByMe: $checkedConvert('reviewedByMe', (v) => v as bool?),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    timeline: $checkedConvert(
      'timeline',
      (v) => (v as List<dynamic>)
          .map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'status': _$BookingStatusEnumMap[instance.status]!,
  'serviceId': instance.serviceId,
  'serviceName': instance.serviceName.toJson(),
  'serviceModel': ?_$ServiceModelEnumMap[instance.serviceModel],
  'provider': ?instance.provider?.toJson(),
  'customer': ?instance.customer?.toJson(),
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'timing': _$TimingEnumMap[instance.timing]!,
  'scheduledAt': ?instance.scheduledAt?.toIso8601String(),
  'endsAt': ?instance.endsAt?.toIso8601String(),
  'address': instance.address.toJson(),
  'note': ?instance.note,
  'acceptDeadline': ?instance.acceptDeadline?.toIso8601String(),
  'pendingExtras': ?instance.pendingExtras?.toJson(),
  'cancellable': ?instance.cancellable,
  'paymentMethod': _$BookingPaymentMethodEnumEnumMap[instance.paymentMethod]!,
  'cashReceived': ?instance.cashReceived,
  'reviewedByMe': ?instance.reviewedByMe,
  'createdAt': instance.createdAt.toIso8601String(),
  'timeline': instance.timeline.map((e) => e.toJson()).toList(),
};

const _$BookingStatusEnumMap = {
  BookingStatus.requested: 'requested',
  BookingStatus.accepted: 'accepted',
  BookingStatus.onTheWay: 'on_the_way',
  BookingStatus.arrived: 'arrived',
  BookingStatus.inProgress: 'in_progress',
  BookingStatus.completed: 'completed',
  BookingStatus.rejected: 'rejected',
  BookingStatus.timedOut: 'timed_out',
  BookingStatus.cancelled: 'cancelled',
};

const _$ServiceModelEnumMap = {
  ServiceModel.onDemand: 'on_demand',
  ServiceModel.durationHire: 'duration_hire',
  ServiceModel.listing: 'listing',
  ServiceModel.partnerReferral: 'partner_referral',
};

const _$TimingEnumMap = {Timing.asap: 'asap', Timing.scheduled: 'scheduled'};

const _$BookingPaymentMethodEnumEnumMap = {
  BookingPaymentMethodEnum.cash: 'cash',
};
