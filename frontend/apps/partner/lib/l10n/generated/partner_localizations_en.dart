// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'partner_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PartnerL10nEn extends PartnerL10n {
  PartnerL10nEn([String locale = 'en']) : super(locale);

  @override
  String get partnerTitle => 'PAO Partner';

  @override
  String get authPhoneTitle => 'What is your phone number?';

  @override
  String get authPhoneBody => 'We will text you a code to sign in.';

  @override
  String get authPhoneLabel => 'Mobile number';

  @override
  String get authPhoneInvalid => 'Enter an 11-digit Bangladeshi mobile number.';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authOtpTitle => 'Enter the 6-digit code';

  @override
  String authOtpSentTo(String phone) {
    return 'We sent it to $phone.';
  }

  @override
  String authResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get authResend => 'Resend code';

  @override
  String get jobsTitle => 'Jobs';

  @override
  String get jobsUpcoming => 'Upcoming';

  @override
  String get jobsPast => 'Past';

  @override
  String get jobsEmptyUpcoming => 'No upcoming jobs';

  @override
  String get jobsEmptyPast => 'No past jobs yet';

  @override
  String get jobsEmptyBody => 'Go online on Home to receive job requests.';

  @override
  String get jobsLoadMore => 'Load more';

  @override
  String get jobsStatusRequested => 'Requested';

  @override
  String get jobsStatusAccepted => 'Accepted';

  @override
  String get jobsStatusOnTheWay => 'On the way';

  @override
  String get jobsStatusArrived => 'Arrived';

  @override
  String get jobsStatusInProgress => 'In progress';

  @override
  String get jobsStatusCompleted => 'Completed';

  @override
  String get jobsStatusRejected => 'Rejected';

  @override
  String get jobsStatusTimedOut => 'Expired';

  @override
  String get jobsStatusCancelled => 'Cancelled';

  @override
  String get jobsDetailTitle => 'Job details';

  @override
  String jobsCustomer(String name) {
    return 'Customer: $name';
  }

  @override
  String jobsArea(String area) {
    return 'Area: $area';
  }

  @override
  String get jobsItems => 'Items';

  @override
  String get jobsExtra => 'Added during the job';

  @override
  String get jobsTotal => 'Total';

  @override
  String get jobsTimeline => 'Timeline';

  @override
  String get jobsOpenLive => 'Continue job';

  @override
  String get jobsReceipt => 'View receipt';

  @override
  String get jobsReceiptTitle => 'Receipt';

  @override
  String get jobsPaidCash => 'Paid in cash';

  @override
  String get jobsReport => 'Report a problem';

  @override
  String get jobsReportTitle => 'Report a problem';

  @override
  String get jobsReportReason => 'What went wrong?';

  @override
  String get jobsReasonCustomerUnavailable => 'Customer not available';

  @override
  String get jobsReasonPayment => 'Payment problem';

  @override
  String get jobsReasonBehaviour => 'Customer behaviour';

  @override
  String get jobsReasonSafety => 'Safety concern';

  @override
  String get jobsReasonDamage => 'Damage';

  @override
  String get jobsReasonOther => 'Something else';

  @override
  String get jobsReportNeedReason => 'Choose a reason.';

  @override
  String get jobsReportDescription => 'Describe the problem';

  @override
  String get jobsReportDescriptionHint => 'What happened, and when?';

  @override
  String get jobsReportDescriptionInvalid =>
      'Write between 10 and 1000 characters.';

  @override
  String jobsReportPhotos(String count, String max) {
    return 'Photos ($count of $max)';
  }

  @override
  String get jobsReportAddPhoto => 'Add photo';

  @override
  String get jobsReportRemovePhoto => 'Remove photo';

  @override
  String get jobsReportSubmit => 'Send report';

  @override
  String get jobsReportSent => 'Report sent';

  @override
  String jobsReportTicket(String ticket) {
    return 'Your ticket number is $ticket. Our team will contact you.';
  }

  @override
  String get jobsBackToJob => 'Back to job';

  @override
  String get earnTitle => 'Earnings';

  @override
  String get earnDay => 'Today';

  @override
  String get earnWeek => 'This week';

  @override
  String get earnMonth => 'This month';

  @override
  String earnJobs(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted jobs',
      one: '$formatted job',
    );
    return '$_temp0';
  }

  @override
  String get earnByJob => 'By job';

  @override
  String get earnEmptyTitle => 'No earnings yet';

  @override
  String get earnEmptyBody => 'Completed jobs and what you earned appear here.';

  @override
  String get profTitle => 'Profile';

  @override
  String get profChangePhoto => 'Change photo';

  @override
  String profLevelOf(String level, String name) {
    return 'Level $level: $name';
  }

  @override
  String profRatingCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted ratings',
      one: '$formatted rating',
      zero: 'No ratings yet',
    );
    return '$_temp0';
  }

  @override
  String get profNoBio => 'Tell customers about your work.';

  @override
  String get profEditBio => 'Edit bio';

  @override
  String get profBioLabel => 'About you';

  @override
  String get profBioHint => 'Your skills and experience';

  @override
  String get profBioTooLong => 'Keep it under 500 characters.';

  @override
  String get profBadgeNone => 'No badge yet';

  @override
  String get profBadgeVerified => 'Verified';

  @override
  String get profBadgeVerifiedPro => 'PAO Verified Pro';

  @override
  String get profLevel0 => 'Registered';

  @override
  String get profLevel1 => 'Document verified';

  @override
  String get profLevel2 => 'Skill verified';

  @override
  String get profLevel0How =>
      'Signed up and verified your phone. You cannot receive bookings yet.';

  @override
  String get profLevel1How =>
      'All documents approved by PAO. Customers see \"Verified\" and you receive bookings.';

  @override
  String get profLevel2How =>
      'PAO checked your work in person. Customers see \"PAO Verified Pro\" and you rank higher.';

  @override
  String get profLevel2Title => 'Level 2 skill check';

  @override
  String get profLevel2Done => 'You are a PAO Verified Pro.';

  @override
  String profLevel2Session(String when, String place) {
    return 'Your skill check is on $when at $place.';
  }

  @override
  String profLevel2Retry(String date) {
    return 'You can try the skill check again after $date.';
  }

  @override
  String get profLevel2Eligible =>
      'You can book a skill check. Call PAO support to arrange one.';

  @override
  String get profLevel2NotYet =>
      'Reach Level 1 first; then PAO can check your work in person.';

  @override
  String get profPublicTitle => 'Public profile';

  @override
  String get profPublicHint =>
      'This is how customers see you. They never see your documents or phone number.';

  @override
  String profExperience(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted years of experience',
      one: '$formatted year of experience',
      zero: 'New to the trade',
    );
    return '$_temp0';
  }

  @override
  String get profReviewsTitle => 'Reviews';

  @override
  String get profReviewsEmpty => 'No reviews yet';

  @override
  String get profReviewsEmptyBody =>
      'Customers can review you after each completed job.';

  @override
  String get profTagOnTime => 'On time';

  @override
  String get profTagProfessional => 'Professional';

  @override
  String get profTagQualityWork => 'Quality work';

  @override
  String get profTagClean => 'Clean';

  @override
  String get profTagFriendly => 'Friendly';

  @override
  String get profTagFairPrice => 'Fair price';

  @override
  String get profTagLate => 'Late';

  @override
  String get profTagRude => 'Rude';

  @override
  String get profTagPoorQuality => 'Poor quality';

  @override
  String get profTagMessy => 'Messy';

  @override
  String get profTagPolite => 'Polite';

  @override
  String get profTagClearInstructions => 'Clear instructions';

  @override
  String get profTagPaidPromptly => 'Paid promptly';

  @override
  String get profTagSafePlace => 'Safe place';

  @override
  String get profTagUnclearInstructions => 'Unclear instructions';

  @override
  String get profTagUnsafePlace => 'Unsafe place';

  @override
  String get profDocumentsTitle => 'Documents';

  @override
  String get profDocumentsEmpty => 'No documents yet';

  @override
  String get profDocumentsUpdate => 'Update documents';

  @override
  String get profItemNid => 'National ID';

  @override
  String get profItemSelfie => 'Live selfie';

  @override
  String get profItemPoliceClearance => 'Police clearance';

  @override
  String get profItemAddress => 'Address';

  @override
  String get profItemEmergencyContact => 'Emergency contact';

  @override
  String get profItemSkillProof => 'Skill proof';

  @override
  String get profItemServiceArea => 'Services and area';

  @override
  String get profItemCodeOfConduct => 'Code of conduct';

  @override
  String get profStatusMissing => 'Missing';

  @override
  String get profStatusPending => 'In review';

  @override
  String get profStatusApproved => 'Approved';

  @override
  String get profStatusRejected => 'Rejected';

  @override
  String get profStatusExpired => 'Expired';

  @override
  String profValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String profExpiresSoon(String date) {
    return 'Expires on $date. Renew it soon to keep receiving bookings.';
  }

  @override
  String profExpired(String date) {
    return 'Expired on $date. Bookings are paused until you renew it.';
  }

  @override
  String get profLevelTitle => 'Badge and level';

  @override
  String get profServicesTitle => 'Services and area';

  @override
  String profServicesPick(String max) {
    return 'Services you offer (up to $max)';
  }

  @override
  String get profExperienceLabel => 'Years of experience';

  @override
  String get profRadius => 'How far you travel';

  @override
  String profRadiusKm(String km) {
    return '$km km';
  }

  @override
  String get profHomeBase => 'Home base';

  @override
  String get profHomeBaseSet => 'Set';

  @override
  String get profHomeBaseMissing => 'Not set';

  @override
  String get profUseLocation => 'Use my location';

  @override
  String get profLocationOff => 'Turn on location and try again.';

  @override
  String get profSaved => 'Saved';

  @override
  String get profLanguageTitle => 'Language';

  @override
  String get profLanguageBody =>
      'Choose the language for the app, notifications and messages from PAO.';

  @override
  String profLanguageNotSynced(String reason) {
    return 'Saved on this phone, but not on your profile: $reason';
  }

  @override
  String get profHelpTitle => 'Help';

  @override
  String get profHelpJobsQ => 'How do I get jobs?';

  @override
  String get profHelpJobsA =>
      'Go online on Home. Requests from nearby customers appear with a countdown; accept them before it ends.';

  @override
  String get profHelpCodeQ => 'What is the start code?';

  @override
  String get profHelpCodeA =>
      'When you arrive, ask the customer for their 4-digit code. The job starts only after you enter it.';

  @override
  String get profHelpCashQ => 'How am I paid?';

  @override
  String get profHelpCashA =>
      'Customers pay you in cash when the job is done. Confirm the cash in the app to complete the job.';

  @override
  String get profHelpDocumentsQ => 'Why did my bookings stop?';

  @override
  String get profHelpDocumentsA =>
      'An expired document, such as the police clearance, pauses bookings. Upload a new one in Documents.';

  @override
  String get profHelpLevelQ => 'How do I become a PAO Verified Pro?';

  @override
  String get profHelpLevelA =>
      'After Level 1, PAO can check your work in person. Passing gives you Level 2 and more bookings.';

  @override
  String get profHelpStillStuck =>
      'Still need help? Our team can help you by phone.';

  @override
  String get profHelpCall => 'Call PAO support';

  @override
  String get profLogOut => 'Log out';

  @override
  String get profLogOutTitle => 'Log out?';

  @override
  String get profLogOutBody =>
      'You will stop receiving job requests on this phone until you sign in again.';
}
