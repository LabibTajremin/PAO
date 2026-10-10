// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AdminL10nEn extends AdminL10n {
  AdminL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PAO Admin';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navVerification => 'Verification';

  @override
  String get navLevel2 => 'Level 2 sessions';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navProviders => 'Providers';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navComplaints => 'Complaints';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginTitle => 'Sign in to PAO Admin';

  @override
  String get loginEmail => 'Work email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginEnrolBody =>
      'First sign-in: add this key to your authenticator app.';

  @override
  String get loginCodeBody =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get loginBack => 'Use another account';

  @override
  String get passwordTitle => 'Choose a new password';

  @override
  String get passwordBody =>
      'Replace the temporary password from your invitation before you continue.';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password (at least 12 characters)';

  @override
  String get passwordRepeat => 'Repeat the new password';

  @override
  String get passwordTooShort =>
      'The new password needs at least 12 characters.';

  @override
  String get passwordMismatch => 'The two new passwords are not the same.';

  @override
  String get reasonLabel => 'Reason';

  @override
  String reasonTooShort(int count) {
    return 'Write at least $count characters.';
  }

  @override
  String get peopleStatusPending => 'Pending';

  @override
  String get peopleStatusActive => 'Active';

  @override
  String get peopleStatusSuspended => 'Suspended';

  @override
  String get peopleStatusBanned => 'Banned';

  @override
  String get peopleFilterStatus => 'Status';

  @override
  String get peopleFilterAny => 'Any';

  @override
  String get peopleName => 'Name';

  @override
  String get peoplePhone => 'Phone';

  @override
  String get peopleRating => 'Rating';

  @override
  String get peopleNoRating => 'No rating yet';

  @override
  String get peopleJoined => 'Joined';

  @override
  String get peopleSuspend => 'Suspend';

  @override
  String get peopleBan => 'Ban';

  @override
  String get peopleReinstate => 'Reinstate';

  @override
  String peopleSuspendTitle(String name) {
    return 'Suspend $name?';
  }

  @override
  String peopleBanTitle(String name) {
    return 'Ban $name? Their phone cannot register again.';
  }

  @override
  String peopleReinstateTitle(String name) {
    return 'Reinstate $name?';
  }

  @override
  String get peopleReasonResolved => 'Issue resolved after review';

  @override
  String get peopleReasonAppeal => 'Appeal accepted';

  @override
  String get peopleStatusChanged => 'Account status updated.';

  @override
  String get peopleRecentBookings => 'Recent bookings';

  @override
  String get peopleNoBookings => 'No bookings yet.';

  @override
  String get peopleHistory => 'Status history';

  @override
  String get peopleHistoryEmpty => 'No status changes yet.';

  @override
  String peopleHistoryBy(String role) {
    return 'by $role';
  }

  @override
  String get providersTitle => 'Providers';

  @override
  String get providersSearch => 'Search providers by name or phone';

  @override
  String get providersEmpty => 'No providers match these filters.';

  @override
  String get providersAll => 'All providers';

  @override
  String get providersLevel => 'Level';

  @override
  String get providersLevel0 => 'Registered';

  @override
  String get providersLevel1 => 'Verified';

  @override
  String get providersLevel2 => 'PAO Verified Pro';

  @override
  String get providersFlagged => 'Flagged for review';

  @override
  String get providersOnline => 'Online';

  @override
  String get providersJobs => 'Jobs done';

  @override
  String get providersProfile => 'Profile';

  @override
  String get providersServices => 'Services';

  @override
  String get providersComplaints => 'Complaints';

  @override
  String get providersCancellations => 'Cancellations (30 days)';

  @override
  String get providersGender => 'Gender';

  @override
  String get providersGenderFemale => 'Female';

  @override
  String get providersGenderMale => 'Male';

  @override
  String get providersGenderOther => 'Other';

  @override
  String get providersExperience => 'Experience';

  @override
  String providersExperienceYears(String years) {
    return '$years years';
  }

  @override
  String get providersVerification => 'Verification';

  @override
  String get providersNoItems => 'Nothing submitted yet.';

  @override
  String get providersOptional => 'optional';

  @override
  String providersItemExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get providersItemNid => 'National ID';

  @override
  String get providersItemSelfie => 'Selfie';

  @override
  String get providersItemPoliceClearance => 'Police clearance';

  @override
  String get providersItemAddress => 'Address';

  @override
  String get providersItemEmergencyContact => 'Emergency contact';

  @override
  String get providersItemSkillProof => 'Skill proof';

  @override
  String get providersItemServiceArea => 'Service area';

  @override
  String get providersItemCodeOfConduct => 'Code of conduct';

  @override
  String get providersItemMissing => 'Missing';

  @override
  String get providersItemPending => 'Pending review';

  @override
  String get providersItemApproved => 'Approved';

  @override
  String get providersItemRejected => 'Rejected';

  @override
  String get providersItemExpired => 'Expired';

  @override
  String providersBanTitle(String name) {
    return 'Ban $name? Their NID, phone and face cannot register again.';
  }

  @override
  String get providersReasonNoShow => 'Repeated no-shows';

  @override
  String get providersReasonComplaint => 'Verified complaint';

  @override
  String get providersReasonRating => 'Rating below the floor';

  @override
  String get providersReasonFraud => 'Forged documents';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersSearch => 'Search customers by name or phone';

  @override
  String get customersEmpty => 'No customers match these filters.';

  @override
  String get customersAll => 'All customers';

  @override
  String get customersBookings => 'Total bookings';

  @override
  String get customersProfile => 'Profile';

  @override
  String get customersComplaints => 'Complaints and reports';

  @override
  String get customersNoComplaints => 'No complaints yet.';

  @override
  String get customersReasonAbuse => 'Abusive behaviour';

  @override
  String get customersReasonFake => 'Repeated fake bookings';

  @override
  String get customersReasonPayment => 'Refused to pay';

  @override
  String get bookingsTitle => 'Bookings';

  @override
  String bookingsAutoRefresh(String seconds) {
    return 'Refreshes every $seconds seconds';
  }

  @override
  String get bookingsAreaHint => 'Filter by area, e.g. Banani';

  @override
  String get bookingsAnyDate => 'Any date';

  @override
  String get bookingsClearDates => 'Clear dates';

  @override
  String get bookingsEmpty => 'No bookings match these filters.';

  @override
  String get bookingsAll => 'All bookings';

  @override
  String get bookingsNumber => 'Booking';

  @override
  String get bookingsService => 'Service';

  @override
  String get bookingsCreated => 'Created';

  @override
  String get bookingsTotal => 'Total';

  @override
  String get bookingsWhen => 'Scheduled for';

  @override
  String get bookingsAsap => 'As soon as possible';

  @override
  String get bookingsEnds => 'Hire ends';

  @override
  String get bookingsStarted => 'Work started';

  @override
  String get bookingsFinished => 'Work completed';

  @override
  String get bookingsPayment => 'Payment';

  @override
  String get bookingsCash => 'Cash';

  @override
  String get bookingsCashReceived => 'Cash received';

  @override
  String get bookingsAddress => 'Address';

  @override
  String get bookingsNote => 'Customer note';

  @override
  String bookingsCancelledBy(String actor) {
    return 'Cancelled by $actor';
  }

  @override
  String get bookingsParties => 'Customer and provider';

  @override
  String get bookingsCustomer => 'Customer';

  @override
  String get bookingsProvider => 'Provider';

  @override
  String get bookingsNotAssigned => 'Not assigned yet';

  @override
  String get bookingsActorSystem => 'System';

  @override
  String get bookingsActorAdmin => 'Admin';

  @override
  String get bookingsItems => 'Items';

  @override
  String bookingsQty(String quantity, String price) {
    return '$quantity × $price';
  }

  @override
  String get bookingsExtra => 'Extra';

  @override
  String get bookingsExtras => 'Proposed extras';

  @override
  String get bookingsExtrasPending => 'Waiting for the customer';

  @override
  String get bookingsExtrasApproved => 'Approved by the customer';

  @override
  String get bookingsExtrasDeclined => 'Declined by the customer';

  @override
  String bookingsExtrasAdded(String added, String total) {
    return 'Adds $added; new total $total';
  }

  @override
  String get bookingsTimeline => 'Timeline';

  @override
  String get bookingsStatusRequested => 'Requested';

  @override
  String get bookingsStatusAccepted => 'Accepted';

  @override
  String get bookingsStatusOnTheWay => 'On the way';

  @override
  String get bookingsStatusArrived => 'Arrived';

  @override
  String get bookingsStatusInProgress => 'In progress';

  @override
  String get bookingsStatusCompleted => 'Completed';

  @override
  String get bookingsStatusRejected => 'Rejected';

  @override
  String get bookingsStatusTimedOut => 'Timed out';

  @override
  String get bookingsStatusCancelled => 'Cancelled';

  @override
  String get complaintsTitle => 'Complaints';

  @override
  String get complaintsMine => 'Assigned to me';

  @override
  String get complaintsEmpty => 'No complaints match these filters.';

  @override
  String get complaintsAll => 'All complaints';

  @override
  String get complaintsTicket => 'Ticket';

  @override
  String get complaintsReason => 'Reason';

  @override
  String get complaintsReporter => 'Reported by';

  @override
  String get complaintsOpened => 'Opened';

  @override
  String get complaintsStatusOpen => 'Open';

  @override
  String get complaintsStatusAssigned => 'Assigned';

  @override
  String get complaintsStatusResolved => 'Resolved';

  @override
  String get complaintsReasonNoShow => 'No-show';

  @override
  String get complaintsReasonLate => 'Late';

  @override
  String get complaintsReasonPoorQuality => 'Poor quality';

  @override
  String get complaintsReasonOvercharge => 'Overcharged';

  @override
  String get complaintsReasonDamage => 'Damage';

  @override
  String get complaintsReasonBehaviour => 'Behaviour';

  @override
  String get complaintsReasonSafety => 'Safety';

  @override
  String get complaintsReasonCustomerUnavailable => 'Customer unavailable';

  @override
  String get complaintsReasonPayment => 'Payment';

  @override
  String get complaintsReasonOther => 'Other';

  @override
  String get complaintsByCustomer => 'Customer';

  @override
  String get complaintsByProvider => 'Provider';

  @override
  String get complaintsAssignee => 'Assigned to';

  @override
  String get complaintsUnassigned => 'Nobody yet';

  @override
  String get complaintsYou => 'You';

  @override
  String complaintsAgent(String id) {
    return 'Agent $id';
  }

  @override
  String get complaintsDescription => 'What happened';

  @override
  String get complaintsOpenBooking => 'Open the booking';

  @override
  String get complaintsReporterProfile => 'Reporter\'s profile';

  @override
  String get complaintsAgainstProfile => 'Other party\'s profile';

  @override
  String get complaintsEvidence => 'Evidence photos';

  @override
  String get complaintsNoEvidence => 'No photos attached.';

  @override
  String complaintsPhoto(String number) {
    return 'Photo $number';
  }

  @override
  String get complaintsPhotoPending =>
      'Opening complaint photos here is not available yet.';

  @override
  String get complaintsComments => 'Internal comments';

  @override
  String get complaintsNoComments => 'No comments yet.';

  @override
  String get complaintsCommentHint => 'Add a note for the team';

  @override
  String get complaintsCommentSend => 'Add comment';

  @override
  String get complaintsCommented => 'Comment added.';

  @override
  String get complaintsActions => 'Actions';

  @override
  String get complaintsAssignMe => 'Assign to me';

  @override
  String get complaintsAssignOther => 'Assign to another agent';

  @override
  String get complaintsPickAgent => 'Choose a support agent';

  @override
  String get complaintsNoAgents => 'No active support agents.';

  @override
  String get complaintsAssigned => 'Complaint assigned.';

  @override
  String get complaintsResolve => 'Resolve';

  @override
  String complaintsResolveTitle(String ticket) {
    return 'Resolve $ticket';
  }

  @override
  String get complaintsResolution => 'Resolution note';

  @override
  String get complaintsVerified => 'Verified complaint';

  @override
  String get complaintsVerifiedHelp =>
      'A verified complaint feeds the provider\'s quality review.';

  @override
  String get complaintsNotVerified => 'Not verified';

  @override
  String get complaintsResolved => 'Complaint resolved.';

  @override
  String get complaintsResolutionTitle => 'Resolution';
}
