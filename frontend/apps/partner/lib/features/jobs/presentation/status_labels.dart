import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_ui/pao_ui.dart';

/// The name of [status] shown to the provider.
String statusLabel(PartnerL10n t, BookingStatus status) => {
  BookingStatus.requested: t.jobsStatusRequested,
  BookingStatus.accepted: t.jobsStatusAccepted,
  BookingStatus.onTheWay: t.jobsStatusOnTheWay,
  BookingStatus.arrived: t.jobsStatusArrived,
  BookingStatus.inProgress: t.jobsStatusInProgress,
  BookingStatus.completed: t.jobsStatusCompleted,
  BookingStatus.rejected: t.jobsStatusRejected,
  BookingStatus.timedOut: t.jobsStatusTimedOut,
  BookingStatus.cancelled: t.jobsStatusCancelled,
}[status]!;

/// The badge colour of [status].
PaoTone statusTone(BookingStatus status) => switch (status) {
  BookingStatus.completed => PaoTone.success,
  BookingStatus.requested => PaoTone.warning,
  BookingStatus.rejected ||
  BookingStatus.timedOut ||
  BookingStatus.cancelled => PaoTone.neutral,
  _ => PaoTone.accent,
};
