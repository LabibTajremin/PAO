// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'customer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CustomerL10nEn extends CustomerL10n {
  CustomerL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PAO';

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
  String get authTermsNote =>
      'By continuing you agree to PAO\'s terms and privacy policy.';

  @override
  String get authTermsLink => 'Read the terms and privacy policy';

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
  String get authProfileTitle => 'Set up your profile';

  @override
  String get authProfileBody =>
      'Tell providers what to call you. A photo is optional.';

  @override
  String get authProfileName => 'Your name';

  @override
  String get authProfileNameInvalid => 'Enter a name of 2 to 80 characters.';

  @override
  String get authProfileAddPhoto => 'Add a photo';

  @override
  String get onbTagline => 'Trusted help at home';

  @override
  String get onbLanguage => 'Language';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbSlide1Title => 'Find help nearby';

  @override
  String get onbSlide1Body =>
      'Electricians, plumbers, cleaners and more, close to your home.';

  @override
  String get onbSlide2Title => 'Verified providers';

  @override
  String get onbSlide2Body =>
      'Every provider\'s NID, police clearance and skills are checked before they work.';

  @override
  String get onbSlide3Title => 'Fixed prices, pay in cash';

  @override
  String get onbSlide3Body =>
      'See the price before you book. Pay the provider in cash when the job is done.';

  @override
  String get bookingSetupTitle => 'Confirm booking';

  @override
  String get bookingNothingTitle => 'Nothing to book yet';

  @override
  String get bookingNothingBody => 'Choose a service and a provider first.';

  @override
  String get bookingBrowse => 'Browse services';

  @override
  String get bookingTotal => 'Total';

  @override
  String bookingLine(String name, String count) {
    return '$name × $count';
  }

  @override
  String get bookingExtra => 'Extra';

  @override
  String bookingRating(String rating, String count) {
    return '★ $rating ($count)';
  }

  @override
  String get bookingBadgeVerified => 'Verified';

  @override
  String get bookingBadgePro => 'Verified Pro';

  @override
  String get bookingWhenTitle => 'When';

  @override
  String get bookingAsap => 'As soon as possible';

  @override
  String get bookingScheduled => 'Schedule';

  @override
  String get bookingPickTime => 'Pick a date and time';

  @override
  String get bookingTimeInvalid =>
      'Pick a time at least 1 hour from now and within 30 days.';

  @override
  String get bookingWhereTitle => 'Where';

  @override
  String get bookingChange => 'Change';

  @override
  String get bookingNoAddress => 'Add an address so the provider can find you.';

  @override
  String get bookingAddAddress => 'Add address';

  @override
  String get bookingAddressTitle => 'Choose address';

  @override
  String get bookingDefault => 'Default';

  @override
  String get bookingLabelHome => 'Home';

  @override
  String get bookingLabelOffice => 'Office';

  @override
  String get bookingLabelOther => 'Other';

  @override
  String get bookingNoteLabel => 'Note for the provider (optional)';

  @override
  String get bookingNoteHint => 'Gate code, floor, landmark…';

  @override
  String get bookingPaymentTitle => 'Payment';

  @override
  String get bookingCash => 'Cash';

  @override
  String get bookingCashBody =>
      'Pay the provider in cash when the job is done.';

  @override
  String bookingConfirm(String amount) {
    return 'Confirm booking · $amount';
  }

  @override
  String get bookingBackHome => 'Back to home';

  @override
  String get bookingWaitingTitle => 'Booking request';

  @override
  String bookingWaitingHeading(String name) {
    return 'Waiting for $name to accept';
  }

  @override
  String get bookingWaitingBody =>
      'We will let you know as soon as the provider answers.';

  @override
  String get bookingWaitingCancel => 'Cancel request';

  @override
  String bookingWaitingDeclinedTitle(String name) {
    return '$name can\'t take this job';
  }

  @override
  String get bookingWaitingTimedOutTitle => 'No answer in time';

  @override
  String get bookingWaitingMissedBody =>
      'Choose another provider nearby. Your items are kept.';

  @override
  String get bookingWaitingChooseAnother => 'Choose another provider';

  @override
  String get bookingConfirmedTitle => 'Booking confirmed';

  @override
  String get bookingConfirmedHeading => 'Your provider accepted. See you then!';

  @override
  String get bookingConfirmedView => 'View booking';

  @override
  String get liveTitle => 'Your booking';

  @override
  String get liveCall => 'Call provider';

  @override
  String get liveStepAccepted => 'Accepted';

  @override
  String get liveStepOnTheWay => 'On the way';

  @override
  String get liveStepArrived => 'Arrived';

  @override
  String get liveStepInProgress => 'In progress';

  @override
  String get liveStepCompleted => 'Completed';

  @override
  String liveAcceptedTitle(String name) {
    return '$name accepted your booking';
  }

  @override
  String get liveAcceptedHint =>
      'They will set off soon. Keep your start code ready.';

  @override
  String liveOnTheWayTitle(String name) {
    return '$name is on the way';
  }

  @override
  String liveArrivedTitle(String name) {
    return '$name has arrived';
  }

  @override
  String get liveArrivedHint => 'Read out the start code so the job can begin.';

  @override
  String get liveInProgressTitle => 'Job in progress';

  @override
  String get liveInProgressHint =>
      'Extra items need your approval before they are added.';

  @override
  String liveScheduledFor(String when) {
    return 'Scheduled for $when';
  }

  @override
  String get liveCodeTitle => 'Start code';

  @override
  String get liveCodeHint =>
      'Share the code only when the provider is with you.';

  @override
  String liveCodeSemantics(String digits) {
    return 'Start code $digits';
  }

  @override
  String get liveExtrasNoticeTitle => 'Extra items to approve';

  @override
  String liveExtrasNoticeBody(String amount) {
    return 'Your provider added $amount of items.';
  }

  @override
  String get liveExtrasNoticeReview => 'Review';

  @override
  String get liveCancel => 'Cancel booking';

  @override
  String get liveReport => 'Report a problem';

  @override
  String get liveApprovalTitle => 'Extra items';

  @override
  String get liveApprovalHeading => 'Your provider added items';

  @override
  String get liveApprovalBody =>
      'Prices are fixed by PAO. Nothing is added without your approval.';

  @override
  String get liveApprovalAdded => 'Added';

  @override
  String get liveApprovalNewTotal => 'New total';

  @override
  String get liveApprovalApprove => 'Approve';

  @override
  String get liveApprovalDecline => 'Decline';

  @override
  String get liveApprovalNone => 'No extra items are waiting for you.';

  @override
  String get liveCompletedTitle => 'Job completed';

  @override
  String get liveCompletedHeading => 'All done!';

  @override
  String liveCompletedPay(String amount) {
    return 'Pay $amount in cash';
  }

  @override
  String liveCompletedPayBody(String name) {
    return 'Hand the cash to $name.';
  }

  @override
  String liveCompletedPaid(String amount) {
    return '$amount paid in cash';
  }

  @override
  String liveCompletedRate(String name) {
    return 'Rate $name';
  }

  @override
  String get liveCompletedReceipt => 'View receipt';

  @override
  String get cancelTitle => 'Cancel booking';

  @override
  String get cancelQuestion => 'Why are you cancelling?';

  @override
  String get cancelFree => 'Cancelling is free until the job starts.';

  @override
  String get cancelReasonChangedMind => 'I changed my mind';

  @override
  String get cancelReasonOtherProvider => 'I found another provider';

  @override
  String get cancelReasonLate => 'The provider is late';

  @override
  String get cancelReasonMistake => 'I booked by mistake';

  @override
  String get cancelReasonOther => 'Something else';

  @override
  String get cancelNote => 'Anything to add? (optional)';

  @override
  String get cancelConfirm => 'Cancel booking';

  @override
  String get cancelKeep => 'Keep booking';

  @override
  String get cancelDoneTitle => 'Booking cancelled';

  @override
  String get cancelDoneBody =>
      'No charge. You can book another provider any time.';

  @override
  String get cancelBookAgain => 'Book another provider';

  @override
  String get cancelBlockedTitle => 'The job has already started';

  @override
  String get cancelBlockedBody =>
      'A booking can\'t be cancelled after the start code is entered. If something is wrong, report a problem.';

  @override
  String get cancelClosedTitle => 'This booking is no longer active';

  @override
  String get ratingTitle => 'Rate provider';

  @override
  String ratingQuestion(String name) {
    return 'How was $name?';
  }

  @override
  String get ratingComment => 'Tell others more (optional)';

  @override
  String get ratingSubmit => 'Submit rating';

  @override
  String get ratingSkip => 'Not now';

  @override
  String get ratingTagOnTime => 'On time';

  @override
  String get ratingTagProfessional => 'Professional';

  @override
  String get ratingTagQuality => 'Quality work';

  @override
  String get ratingTagClean => 'Clean';

  @override
  String get ratingTagFriendly => 'Friendly';

  @override
  String get ratingTagFairPrice => 'Fair price';

  @override
  String get ratingTagLate => 'Late';

  @override
  String get ratingTagRude => 'Rude';

  @override
  String get ratingTagPoorQuality => 'Poor quality';

  @override
  String get ratingTagMessy => 'Messy';

  @override
  String get ratingThanksTitle => 'Thanks for your rating!';

  @override
  String get ratingThanksBody => 'Your feedback keeps PAO safe and reliable.';

  @override
  String get ratingMyBookings => 'My bookings';

  @override
  String get connectivityStale =>
      'Showing the last known status. We will update it when you are back online.';

  @override
  String get connectivityCodeSaved =>
      'You are offline. Your start code is saved on this phone.';
}
