import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_ui/pao_ui.dart';

/// The name of [status] shown to the customer.
String bookingStatusLabel(CustomerL10n t, BookingStatus status) => {
  BookingStatus.requested: t.bookingsStatusRequested,
  BookingStatus.accepted: t.bookingsStatusAccepted,
  BookingStatus.onTheWay: t.bookingsStatusOnTheWay,
  BookingStatus.arrived: t.bookingsStatusArrived,
  BookingStatus.inProgress: t.bookingsStatusInProgress,
  BookingStatus.completed: t.bookingsStatusCompleted,
  BookingStatus.rejected: t.bookingsStatusRejected,
  BookingStatus.timedOut: t.bookingsStatusTimedOut,
  BookingStatus.cancelled: t.bookingsStatusCancelled,
}[status]!;

/// The badge colour of [status].
PaoTone bookingStatusTone(BookingStatus status) => switch (status) {
  BookingStatus.completed => PaoTone.success,
  BookingStatus.requested => PaoTone.warning,
  BookingStatus.rejected ||
  BookingStatus.timedOut ||
  BookingStatus.cancelled => PaoTone.neutral,
  _ => PaoTone.accent,
};

/// The words for a cancel or decline reason code from the timeline; an
/// unknown code is shown as recorded.
String endedReasonLabel(CustomerL10n t, String code) =>
    {
      'changed_mind': t.bookingsReasonChangedMind,
      'found_other_provider': t.bookingsReasonFoundOther,
      'provider_late': t.bookingsReasonProviderLate,
      'booked_by_mistake': t.bookingsReasonByMistake,
      'emergency': t.bookingsReasonEmergency,
      'customer_unreachable': t.bookingsReasonUnreachable,
      'unsafe_location': t.bookingsReasonUnsafe,
      'busy': t.bookingsReasonBusy,
      'too_far': t.bookingsReasonTooFar,
      'not_my_service': t.bookingsReasonNotMyService,
      'other': t.bookingsReasonOther,
    }[code] ??
    code;
