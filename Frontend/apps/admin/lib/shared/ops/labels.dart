import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The name of an account [status] (PRD §6.4).
String accountStatusLabel(AdminL10n t, AccountStatus status) =>
    switch (status) {
      AccountStatus.pending => t.peopleStatusPending,
      AccountStatus.active => t.peopleStatusActive,
      AccountStatus.suspended => t.peopleStatusSuspended,
      AccountStatus.banned => t.peopleStatusBanned,
    };

/// The badge colour of an account [status].
PaoTone accountStatusTone(AccountStatus status) => switch (status) {
  AccountStatus.pending => PaoTone.warning,
  AccountStatus.active => PaoTone.success,
  AccountStatus.suspended => PaoTone.warning,
  AccountStatus.banned => PaoTone.danger,
};

/// The name of a booking [status].
String bookingStatusLabel(AdminL10n t, BookingStatus status) =>
    switch (status) {
      BookingStatus.requested => t.bookingsStatusRequested,
      BookingStatus.accepted => t.bookingsStatusAccepted,
      BookingStatus.onTheWay => t.bookingsStatusOnTheWay,
      BookingStatus.arrived => t.bookingsStatusArrived,
      BookingStatus.inProgress => t.bookingsStatusInProgress,
      BookingStatus.completed => t.bookingsStatusCompleted,
      BookingStatus.rejected => t.bookingsStatusRejected,
      BookingStatus.timedOut => t.bookingsStatusTimedOut,
      BookingStatus.cancelled => t.bookingsStatusCancelled,
    };

/// The badge colour of a booking [status].
PaoTone bookingStatusTone(BookingStatus status) => switch (status) {
  BookingStatus.completed => PaoTone.success,
  BookingStatus.requested => PaoTone.warning,
  BookingStatus.cancelled => PaoTone.danger,
  BookingStatus.rejected || BookingStatus.timedOut => PaoTone.neutral,
  _ => PaoTone.accent,
};

/// The name of a complaint [status].
String complaintStatusLabel(AdminL10n t, ComplaintStatus status) =>
    switch (status) {
      ComplaintStatus.open => t.complaintsStatusOpen,
      ComplaintStatus.assigned => t.complaintsStatusAssigned,
      ComplaintStatus.resolved => t.complaintsStatusResolved,
    };

/// The badge colour of a complaint [status].
PaoTone complaintStatusTone(ComplaintStatus status) => switch (status) {
  ComplaintStatus.open => PaoTone.danger,
  ComplaintStatus.assigned => PaoTone.warning,
  ComplaintStatus.resolved => PaoTone.success,
};

/// Why a complaint was filed.
String complaintReasonLabel(AdminL10n t, ComplaintReason reason) =>
    switch (reason) {
      ComplaintReason.noShow => t.complaintsReasonNoShow,
      ComplaintReason.late_ => t.complaintsReasonLate,
      ComplaintReason.poorQuality => t.complaintsReasonPoorQuality,
      ComplaintReason.overcharge => t.complaintsReasonOvercharge,
      ComplaintReason.damage => t.complaintsReasonDamage,
      ComplaintReason.behaviour => t.complaintsReasonBehaviour,
      ComplaintReason.safety => t.complaintsReasonSafety,
      ComplaintReason.customerUnavailable =>
        t.complaintsReasonCustomerUnavailable,
      ComplaintReason.payment => t.complaintsReasonPayment,
      ComplaintReason.other => t.complaintsReasonOther,
    };

/// Account statuses to filter by, "any" first.
Map<AccountStatus?, String> accountStatusOptions(AdminL10n t) => {
  null: t.peopleFilterAny,
  for (final s in AccountStatus.values) s: accountStatusLabel(t, s),
};

/// Booking statuses to filter by, "any" first.
Map<BookingStatus?, String> bookingStatusOptions(AdminL10n t) => {
  null: t.peopleFilterAny,
  for (final s in BookingStatus.values) s: bookingStatusLabel(t, s),
};

/// Complaint statuses to filter by, "any" first.
Map<ComplaintStatus?, String> complaintStatusOptions(AdminL10n t) => {
  null: t.peopleFilterAny,
  for (final s in ComplaintStatus.values) s: complaintStatusLabel(t, s),
};
