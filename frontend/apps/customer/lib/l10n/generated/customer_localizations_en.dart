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
  String get bookingsTitle => 'My bookings';

  @override
  String get bookingsUpcoming => 'Upcoming';

  @override
  String get bookingsPast => 'Past';

  @override
  String get bookingsEmptyUpcoming => 'No upcoming bookings';

  @override
  String get bookingsEmptyUpcomingBody =>
      'Book a verified provider and the booking will show up here.';

  @override
  String get bookingsEmptyPast => 'No past bookings yet';

  @override
  String get bookingsEmptyPastBody =>
      'Finished and cancelled bookings will appear here.';

  @override
  String get bookingsBookService => 'Book a service';

  @override
  String get bookingsStatusRequested => 'Waiting for reply';

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
  String get bookingsStatusRejected => 'Declined';

  @override
  String get bookingsStatusTimedOut => 'No response';

  @override
  String get bookingsStatusCancelled => 'Cancelled';

  @override
  String get bookingsDetailTitle => 'Booking details';

  @override
  String get bookingsProvider => 'Your provider';

  @override
  String get bookingsCallProvider => 'Call provider';

  @override
  String bookingsRatingSummary(String rating, String count) {
    return '$rating rating · $count reviews';
  }

  @override
  String get bookingsAddress => 'Address';

  @override
  String get bookingsNote => 'Your note';

  @override
  String get bookingsTimeline => 'Timeline';

  @override
  String get bookingsBill => 'Bill';

  @override
  String get bookingsExtra => 'Added during the job';

  @override
  String get bookingsTotal => 'Total';

  @override
  String get bookingsPayCash =>
      'Pay the provider in cash when the job is done.';

  @override
  String get bookingsPaidCash => 'Paid in cash';

  @override
  String get bookingsTrack => 'Track live';

  @override
  String get bookingsWaiting => 'See request status';

  @override
  String get bookingsReceipt => 'View receipt';

  @override
  String get bookingsRate => 'Rate provider';

  @override
  String get bookingsBookAgain => 'Book again';

  @override
  String get bookingsReport => 'Report a problem';

  @override
  String get bookingsCancelledTitle => 'This booking was cancelled';

  @override
  String get bookingsRejectedTitle => 'The provider declined this booking';

  @override
  String get bookingsTimedOutTitle => 'The provider did not answer in time';

  @override
  String get bookingsCancelledByYou => 'You cancelled it.';

  @override
  String get bookingsCancelledByProvider => 'The provider cancelled it.';

  @override
  String get bookingsCancelledByPao => 'PAO cancelled it.';

  @override
  String bookingsEndedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get bookingsNoCharge => 'You were not charged.';

  @override
  String get bookingsReasonChangedMind => 'Changed my mind';

  @override
  String get bookingsReasonFoundOther => 'Found another provider';

  @override
  String get bookingsReasonProviderLate => 'Provider was late';

  @override
  String get bookingsReasonByMistake => 'Booked by mistake';

  @override
  String get bookingsReasonEmergency => 'Provider had an emergency';

  @override
  String get bookingsReasonUnreachable => 'Could not reach you';

  @override
  String get bookingsReasonUnsafe => 'Location felt unsafe';

  @override
  String get bookingsReasonBusy => 'Provider was busy';

  @override
  String get bookingsReasonTooFar => 'Too far away';

  @override
  String get bookingsReasonNotMyService => 'Not a service they offer';

  @override
  String get bookingsReasonOther => 'Other reason';

  @override
  String get bookingsReceiptTitle => 'Receipt';

  @override
  String bookingsReceiptNumber(String number) {
    return 'Receipt $number';
  }

  @override
  String bookingsReceiptCompleted(String date) {
    return 'Completed $date';
  }

  @override
  String get bookingsReceiptService => 'Service';

  @override
  String get bookingsReceiptProvider => 'Provider';

  @override
  String get bookingsReceiptCustomer => 'Customer';

  @override
  String get bookingsReceiptArea => 'Area';

  @override
  String get bookingsReceiptThanks => 'Thank you for choosing PAO.';

  @override
  String get bookingsReceiptShare => 'Share as PDF';

  @override
  String get bookingsReceiptShareFailed =>
      'Could not share the receipt. Please try again.';

  @override
  String get reportTitle => 'Report a problem';

  @override
  String get reportIntro =>
      'Tell us what went wrong. Our support team reads every report.';

  @override
  String get reportReason => 'What went wrong?';

  @override
  String get reportNeedReason => 'Choose a reason.';

  @override
  String get reportReasonNoShow => 'Provider did not come';

  @override
  String get reportReasonLate => 'Provider was late';

  @override
  String get reportReasonPoorQuality => 'Poor quality work';

  @override
  String get reportReasonOvercharge => 'Charged more than the price';

  @override
  String get reportReasonDamage => 'Something was damaged';

  @override
  String get reportReasonBehaviour => 'Rude or unprofessional';

  @override
  String get reportReasonSafety => 'I felt unsafe';

  @override
  String get reportReasonPayment => 'Payment problem';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportDescription => 'Describe the problem';

  @override
  String get reportDescriptionHint => 'What happened, and when?';

  @override
  String get reportDescriptionInvalid => 'Write 10 to 1000 characters.';

  @override
  String reportPhotos(String count, String max) {
    return 'Photos ($count of $max)';
  }

  @override
  String get reportTakePhoto => 'Take photo';

  @override
  String get reportChoosePhoto => 'Choose photo';

  @override
  String get reportRemovePhoto => 'Remove photo';

  @override
  String get reportSubmit => 'Send report';

  @override
  String get reportSent => 'Report sent';

  @override
  String reportTicket(String ticket) {
    return 'Your ticket number is $ticket. Our team will review it and contact you.';
  }

  @override
  String get reportBackToBooking => 'Back to booking';

  @override
  String get notifReadAll => 'Mark all read';

  @override
  String get notifEmpty => 'No notifications yet';

  @override
  String get notifEmptyBody => 'Updates about your bookings will appear here.';

  @override
  String get notifUnread => 'Unread';

  @override
  String get accountEditProfile => 'Edit profile';

  @override
  String get accountAddresses => 'Saved addresses';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountHelp => 'Help & support';

  @override
  String get accountLegal => 'Terms & privacy';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountLogOut => 'Log out';

  @override
  String get accountLogOutTitle => 'Log out of PAO?';

  @override
  String get accountLogOutBody =>
      'You will need your phone number and a code to sign in again.';

  @override
  String get accountChangePhoto => 'Change photo';

  @override
  String get accountProfileSaved => 'Profile saved';

  @override
  String get accountAddressesEmpty => 'No saved addresses';

  @override
  String get accountAddressesEmptyBody =>
      'Save your home or office to book faster.';

  @override
  String get accountAddressAdd => 'Add address';

  @override
  String accountAddressLimit(String max) {
    return 'You can save up to $max addresses.';
  }

  @override
  String get accountAddressDefault => 'Default';

  @override
  String get accountAddressMakeDefault => 'Make default';

  @override
  String get accountAddressEdit => 'Edit';

  @override
  String get accountAddressDelete => 'Delete';

  @override
  String get accountAddressDeleteTitle => 'Delete this address?';

  @override
  String get accountAddressDeleteBody =>
      'It will be removed from your saved addresses.';

  @override
  String get accountAddressActions => 'Address actions';

  @override
  String get accountAddressHome => 'Home';

  @override
  String get accountAddressOffice => 'Office';

  @override
  String get accountAddressOther => 'Other';

  @override
  String get accountLanguageBody =>
      'Choose the language for the app, notifications and SMS.';

  @override
  String accountLanguageNotSynced(String reason) {
    return 'Saved on this phone but not on your profile yet: $reason';
  }

  @override
  String get accountHelpIntro => 'Answers to common questions';

  @override
  String get accountHelpBookQ => 'How do I book a service?';

  @override
  String get accountHelpBookA =>
      'Pick a service, choose a nearby verified provider, then confirm the time and address. The provider has a few minutes to accept.';

  @override
  String get accountHelpPayQ => 'How do I pay?';

  @override
  String get accountHelpPayA =>
      'Pay the provider in cash when the job is done. You pay the price shown when booking, plus any extras you approve.';

  @override
  String get accountHelpCodeQ => 'What is the start code?';

  @override
  String get accountHelpCodeA =>
      'When the provider arrives, tell them the 4-digit code from the app. The job starts only after they enter it, so you know the right person is at your door.';

  @override
  String get accountHelpCancelQ => 'Can I cancel a booking?';

  @override
  String get accountHelpCancelA =>
      'Yes, until the job starts. Open the booking, tap Cancel and pick a reason.';

  @override
  String get accountHelpProblemQ => 'Something went wrong. What now?';

  @override
  String get accountHelpProblemA =>
      'Open the booking and tap Report a problem. Our support team reviews every report.';

  @override
  String get accountHelpStillStuck =>
      'Still need help? Our support team is here for you.';

  @override
  String get accountHelpCall => 'Call support';

  @override
  String get accountHelpEmail => 'Email support';

  @override
  String get accountHelpEmailSubject => 'PAO support request';

  @override
  String get accountLegalTermsHeading => 'Terms of use';

  @override
  String get accountLegalTermsBody =>
      'PAO connects you with independent, verified service providers. Prices are fixed and shown before you book; extra work needs your approval in the app. You pay the provider in cash when the job is done. Please be at the address on time, treat providers with respect and cancel early if your plans change. Accounts that misuse PAO may be suspended.';

  @override
  String get accountLegalPrivacyHeading => 'Privacy';

  @override
  String get accountLegalPrivacyBody =>
      'We keep your name, phone number, photo and saved addresses to run your bookings. A provider sees your exact address and phone number only after accepting your booking. We use your location only when you ask us to find it. We never sell your data.';

  @override
  String get accountLegalChoicesHeading => 'Your choices';

  @override
  String get accountLegalChoicesBody =>
      'You can change your profile and language at any time, and delete your account from the Account tab. Deleting removes your personal details; records of past bookings are kept without them.';

  @override
  String get accountDeleteHeading => 'Before you go';

  @override
  String get accountDeleteBody =>
      'Deleting your account removes your name, photo, phone number and saved addresses, and signs you out on every device. This cannot be undone.';

  @override
  String get accountDeleteRecords =>
      'Records of past bookings are kept without your personal details.';

  @override
  String get accountDeleteSendCode => 'Send confirmation code';

  @override
  String get accountDeleteCodeTitle => 'Enter the code';

  @override
  String accountDeleteCodeBody(String phone) {
    return 'We sent a 6-digit code to $phone. Enter it to delete your account.';
  }

  @override
  String get accountDeleteResend => 'Send a new code';

  @override
  String get accountDeleteConfirm => 'Delete my account';

  @override
  String get accountDeletedTitle => 'Your account is deleted';

  @override
  String get accountDeletedBody =>
      'Thank you for using PAO. You can create a new account with your phone number at any time.';
}
