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

  @override
  String get verifyQueueTitle => 'Verification queue';

  @override
  String get verifyQueueEmpty => 'No providers are waiting for review.';

  @override
  String get verifyFilterItem => 'Pending item';

  @override
  String get verifyFilterAll => 'All items';

  @override
  String get verifyColProvider => 'Provider';

  @override
  String get verifyColServices => 'Services';

  @override
  String get verifyColPending => 'Waiting for review';

  @override
  String get verifyColWaiting => 'Waiting for';

  @override
  String verifyAgeHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String verifyAgeDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get verifyItemNid => 'National ID';

  @override
  String get verifyItemSelfie => 'Live selfie';

  @override
  String get verifyItemPolice => 'Police clearance';

  @override
  String get verifyItemAddress => 'Address';

  @override
  String get verifyItemEmergency => 'Emergency contact';

  @override
  String get verifyItemSkill => 'Skill proof';

  @override
  String get verifyItemServiceArea => 'Service area';

  @override
  String get verifyItemConduct => 'Code of conduct';

  @override
  String get verifyStatusMissing => 'Missing';

  @override
  String get verifyStatusPending => 'Pending';

  @override
  String get verifyStatusApproved => 'Approved';

  @override
  String get verifyStatusRejected => 'Rejected';

  @override
  String get verifyStatusExpired => 'Expired';

  @override
  String get verifyRequired => 'Required';

  @override
  String get verifyOptional => 'Optional';

  @override
  String get verifyLevel0 => 'Level 0 · Registered';

  @override
  String get verifyLevel1 => 'Level 1 · Verified';

  @override
  String get verifyLevel2 => 'Level 2 · PAO Verified Pro';

  @override
  String get verifyFaceTitle => 'Face match';

  @override
  String get verifyFaceNotRun => 'Not checked yet';

  @override
  String get verifyFaceMatch => 'Face matches';

  @override
  String get verifyFaceNoMatch => 'Face does not match';

  @override
  String get verifyFaceManual => 'Compare the selfie with the NID photo';

  @override
  String get verifyGenderFemale => 'Female';

  @override
  String get verifyGenderMale => 'Male';

  @override
  String get verifyGenderOther => 'Other';

  @override
  String get verifyDocNidFront => 'NID front';

  @override
  String get verifyDocNidBack => 'NID back';

  @override
  String get verifyFieldIssueDate => 'Issue date';

  @override
  String get verifyFieldRadius => 'Working radius (m)';

  @override
  String get verifyFieldServices => 'Services chosen';

  @override
  String get verifyFieldHomeLat => 'Home latitude';

  @override
  String get verifyFieldHomeLng => 'Home longitude';

  @override
  String get verifyFieldName => 'Name';

  @override
  String get verifyFieldRelation => 'Relation';

  @override
  String get verifyProfileTitle => 'NID and profile';

  @override
  String get verifyNidNumber => 'NID number';

  @override
  String get verifyFullName => 'Full name';

  @override
  String get verifyDob => 'Date of birth';

  @override
  String get verifyGender => 'Gender';

  @override
  String get verifyPhone => 'Phone';

  @override
  String get verifyPresentAddress => 'Present address';

  @override
  String get verifyPermanentAddress => 'Permanent address';

  @override
  String get verifyNotGiven => 'Not given';

  @override
  String get verifyReasonBlurry =>
      'The photo is blurry. Retake it in good light.';

  @override
  String get verifyReasonName => 'The name does not match the profile.';

  @override
  String get verifyReasonExpired => 'The document has expired.';

  @override
  String get verifyReasonFace => 'The selfie does not match the NID photo.';

  @override
  String get verifyReasonCropped => 'Part of the document is cut off.';

  @override
  String verifyRejectedBecause(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String verifyExpires(String date) {
    return 'Expires $date';
  }

  @override
  String verifyDecidedAt(String date) {
    return 'Decided $date';
  }

  @override
  String get verifyOpenDocs => 'Open documents';

  @override
  String get verifyDocsLocked => 'You may not open documents';

  @override
  String get verifyApprove => 'Approve';

  @override
  String get verifyReject => 'Reject';

  @override
  String verifyRejectTitle(String item) {
    return 'Reject $item';
  }

  @override
  String get verifyReviewTitle => 'Verification review';

  @override
  String get verifyBackToQueue => 'Back to the queue';

  @override
  String get verifyNext => 'Next provider';

  @override
  String get verifyShortcuts => 'Keys: A approve · R reject · N next · ↑↓ move';

  @override
  String get verifyNoPending => 'Nothing is waiting for a decision.';

  @override
  String verifyDecided(String level) {
    return 'Saved. The provider is now at $level.';
  }

  @override
  String get verifyQueueDone => 'No other providers are waiting.';

  @override
  String get verifyViewerBroken => 'This document could not be shown.';

  @override
  String get verifyViewerZoomIn => 'Zoom in';

  @override
  String get verifyViewerZoomOut => 'Zoom out';

  @override
  String get verifyViewerRotateLeft => 'Rotate left';

  @override
  String get verifyViewerRotateRight => 'Rotate right';

  @override
  String get level2Title => 'Level 2 sessions';

  @override
  String get level2Schedule => 'Schedule session';

  @override
  String get level2Empty => 'No sessions match.';

  @override
  String get level2ColWhen => 'When';

  @override
  String get level2ColProvider => 'Provider';

  @override
  String get level2ColService => 'Service';

  @override
  String get level2ColStatus => 'Status';

  @override
  String get level2StatusScheduled => 'Scheduled';

  @override
  String get level2StatusCompleted => 'Completed';

  @override
  String get level2StatusCancelled => 'Cancelled';

  @override
  String get level2ResultPass => 'Pass';

  @override
  String get level2ResultFail => 'Fail';

  @override
  String get level2ResultRetest => 'Retest';

  @override
  String get level2FilterStatus => 'Status';

  @override
  String get level2AllStatuses => 'All statuses';

  @override
  String get level2FilterProvider => 'Provider';

  @override
  String get level2AnyProvider => 'Any';

  @override
  String get level2FindProvider => 'Find a provider';

  @override
  String get level2FindHint => 'Name or phone, then Enter';

  @override
  String get level2NoProviders => 'No provider matches.';

  @override
  String get level2ScheduleTitle => 'Schedule a Level 2 session';

  @override
  String get level2ChangeProvider => 'Change';

  @override
  String get level2NoServices => 'This provider has not chosen any service.';

  @override
  String get level2Service => 'Service';

  @override
  String get level2Date => 'Date';

  @override
  String get level2Time => 'Time (Dhaka)';

  @override
  String get level2Location => 'Location';

  @override
  String get level2LocationHint => 'PAO office, Gulshan 1';

  @override
  String get level2ScheduleSubmit => 'Schedule';

  @override
  String get level2ScheduleMissing =>
      'Choose a provider, a service and a location.';

  @override
  String get level2PastTime => 'Choose a time in the future.';

  @override
  String get level2Booked =>
      'Session scheduled. The provider will be notified.';

  @override
  String get level2NotEligible =>
      'Only Level 1 providers can take a Level 2 session.';

  @override
  String get level2CoolingOff =>
      'This provider failed recently and must wait before retrying.';

  @override
  String get level2SessionTitle => 'Level 2 session';

  @override
  String get level2Checklist => 'Checklist';

  @override
  String get level2ItemPassed => 'Passed';

  @override
  String get level2ItemFailed => 'Not passed';

  @override
  String get level2AddItem => 'Add a checklist item';

  @override
  String get level2Outcome => 'Result';

  @override
  String get level2Notes => 'Notes';

  @override
  String get level2Record => 'Record result';

  @override
  String get level2NeedChecklist => 'Add at least one checklist item.';

  @override
  String get level2NeedResult => 'Choose pass, fail or retest.';

  @override
  String get formRequired => 'Fill this in.';

  @override
  String formTooLong(String max) {
    return 'Keep it to $max characters or fewer.';
  }

  @override
  String get formWhole => 'Enter a whole number.';

  @override
  String get formNumber => 'Enter a number.';

  @override
  String formAtLeast(String min) {
    return 'Enter $min or more.';
  }

  @override
  String formRange(String min, String max) {
    return 'Enter a number from $min to $max.';
  }

  @override
  String get formMoney => 'Enter an amount in taka, such as 500 or 499.50.';

  @override
  String get formEmail => 'Enter a valid email address.';

  @override
  String get formSaved => 'Saved.';

  @override
  String get dashTitle => 'Dashboard';

  @override
  String dashUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get dashRefresh => 'Refresh';

  @override
  String get dashPendingVerifications => 'Pending verifications';

  @override
  String get dashOpenComplaints => 'Open complaints';

  @override
  String get dashCompletionRate => 'Completion rate';

  @override
  String get dashBookings => 'Bookings in this period';

  @override
  String get dashActiveProviders => 'Active providers';

  @override
  String get dashBookingsPerDay => 'Bookings per day';

  @override
  String get dashLegendTotal => 'All bookings';

  @override
  String get dashLegendCompleted => 'Completed';

  @override
  String dashDayTip(String day, String total, String completed) {
    return '$day: $total bookings, $completed completed';
  }

  @override
  String get dashNoBookings => 'No bookings in this period yet.';

  @override
  String get dashProvidersByStatus => 'Providers by status';

  @override
  String get dashProvidersByLevel => 'Providers by level';

  @override
  String get dashNoProviders => 'No providers yet.';

  @override
  String get dashStatusPending => 'Pending';

  @override
  String get dashStatusActive => 'Active';

  @override
  String get dashStatusSuspended => 'Suspended';

  @override
  String get dashStatusBanned => 'Banned';

  @override
  String get dashLevel0 => 'Level 0 · Registered';

  @override
  String get dashLevel1 => 'Level 1 · Verified';

  @override
  String get dashLevel2 => 'Level 2 · PAO Verified Pro';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String catalogVersion(String version) {
    return 'Version $version';
  }

  @override
  String get catalogEmptyTitle => 'No categories yet';

  @override
  String get catalogEmptyBody =>
      'Add a category, then the services customers can book in it.';

  @override
  String get catalogNewCategory => 'New category';

  @override
  String get catalogEditCategory => 'Edit category';

  @override
  String catalogCategoryLine(String other, String order, String count) {
    return '$other · order $order · $count services';
  }

  @override
  String get catalogNewService => 'New service';

  @override
  String get catalogServiceTitle => 'Service';

  @override
  String get catalogBack => 'Back to catalog';

  @override
  String get catalogPublished => 'Published';

  @override
  String get catalogHidden => 'Hidden';

  @override
  String get catalogPublishedSwitch => 'Published';

  @override
  String get catalogPublishedHint => 'Customers see it in the apps.';

  @override
  String get catalogName => 'Name';

  @override
  String get catalogDescription => 'Description';

  @override
  String catalogInEnglish(String label) {
    return '$label (English)';
  }

  @override
  String catalogInBangla(String label) {
    return '$label (Bangla)';
  }

  @override
  String get catalogIconKey => 'Icon key';

  @override
  String get catalogPickIcon => 'Pick a known icon';

  @override
  String get catalogSortOrder => 'Sort order';

  @override
  String get catalogAddRow => 'Add';

  @override
  String get catalogRemoveRow => 'Remove';

  @override
  String get catalogServiceDetails => 'Service details';

  @override
  String get catalogCategory => 'Category';

  @override
  String get catalogModel => 'Service model';

  @override
  String get catalogLevel => 'Required level';

  @override
  String get catalogRadius => 'Search radius (metres)';

  @override
  String get catalogRadiusHint => 'From 500 to 50000';

  @override
  String get catalogWomenOnly => 'Women providers only';

  @override
  String get catalogWomenOnlyHint => 'Requests go only to women providers.';

  @override
  String get catalogRequiresLevel2 => 'Requires Level 2';

  @override
  String get catalogRequiresLevel2Hint =>
      'Providers pass an in-person skill check first.';

  @override
  String get catalogChecklistItem => 'Checklist item';

  @override
  String get catalogModelOnDemand => 'On-demand visit';

  @override
  String get catalogModelDuration => 'Duration hire';

  @override
  String get catalogModelListing => 'Listing';

  @override
  String get catalogModelPartner => 'Partner referral';

  @override
  String get catalogUnitJob => 'per job';

  @override
  String get catalogUnitUnit => 'per unit';

  @override
  String get catalogUnitHour => 'per hour';

  @override
  String get catalogUnitDay => 'per day';

  @override
  String get catalogSubServices => 'Sub-services';

  @override
  String get catalogNoSubServices =>
      'No sub-services yet. Add one so customers can book this service.';

  @override
  String get catalogNewSubService => 'New sub-service';

  @override
  String get catalogEditSub => 'Edit sub-service';

  @override
  String catalogMaxLine(String count) {
    return 'up to $count';
  }

  @override
  String get catalogInclusion => 'Included';

  @override
  String get catalogExclusion => 'Not included';

  @override
  String get catalogUnit => 'Priced';

  @override
  String get catalogMaxQuantity => 'Most per booking';

  @override
  String get catalogMaxQuantityHint => 'Leave empty for no limit';

  @override
  String get catalogFirstPrice => 'Price';

  @override
  String get catalogPrices => 'Prices';

  @override
  String catalogPricesOf(String name) {
    return 'Prices of $name';
  }

  @override
  String get catalogPriceNote =>
      'A new price applies to bookings made from now on. Earlier bookings keep the price they were made at.';

  @override
  String catalogNewPrice(String unit) {
    return 'New price ($unit)';
  }

  @override
  String get catalogSetPrice => 'Set new price';

  @override
  String get catalogPriceChanged => 'Price updated.';

  @override
  String get catalogPriceHistory => 'Price history';

  @override
  String get catalogNoPrices => 'No prices recorded yet.';

  @override
  String catalogPriceSince(String when, String admin) {
    return 'From $when · by $admin';
  }

  @override
  String get catalogCurrentPrice => 'Current';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTabSettings => 'Platform settings';

  @override
  String get settingsTabAdmins => 'Admin users';

  @override
  String get settingsTabRoles => 'Roles';

  @override
  String get settingsTabAudit => 'Audit log';

  @override
  String get settingsEmpty => 'No settings yet';

  @override
  String get settingsSearch => 'Search settings';

  @override
  String settingsUpdatedAt(String when) {
    return 'Changed $when';
  }

  @override
  String get settingsEdit => 'Change setting';

  @override
  String get settingsValue => 'Value';

  @override
  String get settingsOn => 'On';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsShape => 'Map shape';

  @override
  String get settingsBadShape => 'Paste a GeoJSON object with a \"type\".';

  @override
  String get settingsApplyNow =>
      'The change applies right away and is recorded in the audit log.';

  @override
  String get settingsRoleCustomer => 'Customer';

  @override
  String get settingsRoleProvider => 'Provider';

  @override
  String get settingsRoleVerifier => 'Verifier';

  @override
  String get settingsRoleCatalogManager => 'Catalog manager';

  @override
  String get settingsRoleSupportAgent => 'Support agent';

  @override
  String get settingsRoleSuperAdmin => 'Super admin';

  @override
  String get adminsInvite => 'Invite admin';

  @override
  String get adminsSendInvite => 'Send invite';

  @override
  String get adminsEmpty => 'No admin users yet';

  @override
  String get adminsEmail => 'Work email';

  @override
  String get adminsName => 'Full name';

  @override
  String get adminsNameShort => 'Write at least 2 characters.';

  @override
  String get adminsRoles => 'Roles';

  @override
  String get adminsPickRole => 'Pick at least one role.';

  @override
  String get adminsInvitedTitle => 'Invitation created';

  @override
  String adminsInvitedBody(String name) {
    return 'Give this temporary password to $name privately. It is shown only once; they replace it and set up 2FA when they first sign in.';
  }

  @override
  String get adminsCopy => 'Copy password';

  @override
  String get adminsCopied => 'Copied.';

  @override
  String get adminsDone => 'Done';

  @override
  String get adminsNeverSignedIn => 'Has not signed in yet';

  @override
  String adminsLastSignIn(String when) {
    return 'Last signed in $when';
  }

  @override
  String get adminsActive => 'Active';

  @override
  String get adminsInactive => 'Deactivated';

  @override
  String get adminsTotpOn => '2FA set up';

  @override
  String get adminsTotpOff => '2FA pending';

  @override
  String get adminsEdit => 'Change roles or access';

  @override
  String get adminsActiveSwitch => 'Can sign in';

  @override
  String get adminsActiveHint =>
      'Turning this off ends their sessions at once.';

  @override
  String adminsDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get adminsDeactivateBody =>
      'They are signed out everywhere now and cannot sign in until reactivated.';

  @override
  String get adminsDeactivate => 'Deactivate';

  @override
  String get rolesEmpty => 'No roles found';

  @override
  String get rolesApplyNow =>
      'Role changes apply immediately to everyone who holds the role.';

  @override
  String rolesCounts(String permissions, String screens) {
    return '$permissions permissions · $screens screens';
  }

  @override
  String get rolesEdit => 'Edit role';

  @override
  String get rolesPermissions => 'Permissions';

  @override
  String get rolesScreens => 'Screens';

  @override
  String rolesConfirmTitle(String role) {
    return 'Apply the changes to $role?';
  }

  @override
  String get rolesApply => 'Apply now';

  @override
  String get rolesSaved => 'Role updated.';

  @override
  String get auditWhen => 'When';

  @override
  String get auditActor => 'Who';

  @override
  String get auditRole => 'Role';

  @override
  String get auditAction => 'Action';

  @override
  String get auditSubject => 'Subject';

  @override
  String get auditReason => 'Reason';

  @override
  String get auditBefore => 'Before';

  @override
  String get auditAfter => 'After';

  @override
  String get auditSystem => 'System';

  @override
  String get auditEmpty => 'No audit entries match';

  @override
  String get auditActorId => 'Actor ID';

  @override
  String get auditActorInvalid => 'Paste a full account ID.';

  @override
  String get auditActionHint => 'Action, e.g. catalog.price_changed';

  @override
  String get auditSubjectId => 'Subject ID';

  @override
  String get auditAnyDate => 'Any date';

  @override
  String get auditApply => 'Apply';

  @override
  String get auditClear => 'Clear';
}
