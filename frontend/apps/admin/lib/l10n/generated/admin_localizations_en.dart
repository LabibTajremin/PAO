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
}
