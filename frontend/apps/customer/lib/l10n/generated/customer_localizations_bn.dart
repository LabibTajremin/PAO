// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'customer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class CustomerL10nBn extends CustomerL10n {
  CustomerL10nBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'পাও';

  @override
  String get authPhoneTitle => 'আপনার ফোন নম্বর কত?';

  @override
  String get authPhoneBody => 'সাইন ইনের জন্য আমরা একটি কোড পাঠাব।';

  @override
  String get authPhoneLabel => 'মোবাইল নম্বর';

  @override
  String get authPhoneInvalid => '১১ সংখ্যার বাংলাদেশি মোবাইল নম্বর দিন।';

  @override
  String get authSendCode => 'কোড পাঠান';

  @override
  String get authTermsNote =>
      'এগিয়ে গেলে আপনি পাও-এর শর্তাবলি ও গোপনীয়তা নীতিতে সম্মত হচ্ছেন।';

  @override
  String get authTermsLink => 'শর্তাবলি ও গোপনীয়তা নীতি পড়ুন';

  @override
  String get authOtpTitle => '৬ সংখ্যার কোডটি দিন';

  @override
  String authOtpSentTo(String phone) {
    return 'আমরা $phone নম্বরে পাঠিয়েছি।';
  }

  @override
  String authResendIn(int seconds) {
    return '$seconds সেকেন্ড পর আবার কোড পাঠান';
  }

  @override
  String get authResend => 'আবার কোড পাঠান';

  @override
  String get authProfileTitle => 'আপনার প্রোফাইল তৈরি করুন';

  @override
  String get authProfileBody =>
      'সেবাদাতারা আপনাকে কী নামে ডাকবেন তা লিখুন। ছবি দেওয়া ঐচ্ছিক।';

  @override
  String get authProfileName => 'আপনার নাম';

  @override
  String get authProfileNameInvalid => '২ থেকে ৮০ অক্ষরের একটি নাম দিন।';

  @override
  String get authProfileAddPhoto => 'ছবি যোগ করুন';

  @override
  String get onbTagline => 'ঘরের কাজে বিশ্বস্ত সাহায্য';

  @override
  String get onbLanguage => 'ভাষা';

  @override
  String get onbSkip => 'এড়িয়ে যান';

  @override
  String get onbNext => 'পরবর্তী';

  @override
  String get onbStart => 'শুরু করুন';

  @override
  String get onbSlide1Title => 'কাছাকাছি সাহায্য খুঁজুন';

  @override
  String get onbSlide1Body =>
      'ইলেকট্রিশিয়ান, প্লাম্বার, পরিচ্ছন্নতাকর্মী ও আরও অনেকে, আপনার বাসার কাছেই।';

  @override
  String get onbSlide2Title => 'যাচাইকৃত সেবাদাতা';

  @override
  String get onbSlide2Body =>
      'কাজ শুরুর আগে প্রত্যেক সেবাদাতার এনআইডি, পুলিশ ক্লিয়ারেন্স ও দক্ষতা যাচাই করা হয়।';

  @override
  String get onbSlide3Title => 'নির্দিষ্ট দাম, নগদে পরিশোধ';

  @override
  String get onbSlide3Body =>
      'বুক করার আগেই দাম দেখুন। কাজ শেষে সেবাদাতাকে নগদে টাকা দিন।';

  @override
  String get bookingSetupTitle => 'বুকিং নিশ্চিত করুন';

  @override
  String get bookingNothingTitle => 'এখনও বুক করার কিছু নেই';

  @override
  String get bookingNothingBody => 'আগে একটি সেবা ও সেবাদাতা বেছে নিন।';

  @override
  String get bookingBrowse => 'সেবাগুলো দেখুন';

  @override
  String get bookingTotal => 'মোট';

  @override
  String bookingLine(String name, String count) {
    return '$name × $count';
  }

  @override
  String get bookingExtra => 'অতিরিক্ত';

  @override
  String bookingRating(String rating, String count) {
    return '★ $rating ($count)';
  }

  @override
  String get bookingBadgeVerified => 'যাচাইকৃত';

  @override
  String get bookingBadgePro => 'যাচাইকৃত প্রো';

  @override
  String get bookingWhenTitle => 'কখন';

  @override
  String get bookingAsap => 'যত দ্রুত সম্ভব';

  @override
  String get bookingScheduled => 'সময় ঠিক করুন';

  @override
  String get bookingPickTime => 'তারিখ ও সময় বেছে নিন';

  @override
  String get bookingTimeInvalid =>
      'এখন থেকে অন্তত ১ ঘণ্টা পরের এবং ৩০ দিনের মধ্যের একটি সময় বেছে নিন।';

  @override
  String get bookingWhereTitle => 'কোথায়';

  @override
  String get bookingChange => 'পরিবর্তন';

  @override
  String get bookingNoAddress =>
      'সেবাদাতা যেন আপনাকে খুঁজে পান, তাই একটি ঠিকানা যোগ করুন।';

  @override
  String get bookingAddAddress => 'ঠিকানা যোগ করুন';

  @override
  String get bookingAddressTitle => 'ঠিকানা বেছে নিন';

  @override
  String get bookingDefault => 'ডিফল্ট';

  @override
  String get bookingLabelHome => 'বাসা';

  @override
  String get bookingLabelOffice => 'অফিস';

  @override
  String get bookingLabelOther => 'অন্যান্য';

  @override
  String get bookingNoteLabel => 'সেবাদাতার জন্য নোট (ঐচ্ছিক)';

  @override
  String get bookingNoteHint => 'গেট কোড, তলা, কাছের চিহ্ন…';

  @override
  String get bookingPaymentTitle => 'পেমেন্ট';

  @override
  String get bookingCash => 'নগদ';

  @override
  String get bookingCashBody => 'কাজ শেষে সেবাদাতাকে নগদে টাকা দিন।';

  @override
  String bookingConfirm(String amount) {
    return 'বুকিং নিশ্চিত করুন · $amount';
  }

  @override
  String get bookingBackHome => 'হোমে ফিরুন';

  @override
  String get bookingWaitingTitle => 'বুকিং অনুরোধ';

  @override
  String bookingWaitingHeading(String name) {
    return '$name-এর সম্মতির অপেক্ষায়';
  }

  @override
  String get bookingWaitingBody => 'সেবাদাতা উত্তর দিলেই আমরা আপনাকে জানাব।';

  @override
  String get bookingWaitingCancel => 'অনুরোধ বাতিল করুন';

  @override
  String bookingWaitingDeclinedTitle(String name) {
    return '$name এই কাজটি নিতে পারছেন না';
  }

  @override
  String get bookingWaitingTimedOutTitle => 'সময়মতো কোনো উত্তর আসেনি';

  @override
  String get bookingWaitingMissedBody =>
      'কাছের অন্য একজন সেবাদাতা বেছে নিন। আপনার বাছাই করা আইটেম রাখা আছে।';

  @override
  String get bookingWaitingChooseAnother => 'অন্য সেবাদাতা বেছে নিন';

  @override
  String get bookingConfirmedTitle => 'বুকিং নিশ্চিত হয়েছে';

  @override
  String get bookingConfirmedHeading =>
      'আপনার সেবাদাতা রাজি হয়েছেন। নির্ধারিত সময়ে দেখা হবে!';

  @override
  String get bookingConfirmedView => 'বুকিং দেখুন';

  @override
  String get liveTitle => 'আপনার বুকিং';

  @override
  String get liveCall => 'সেবাদাতাকে কল করুন';

  @override
  String get liveStepAccepted => 'গ্রহণ করেছেন';

  @override
  String get liveStepOnTheWay => 'পথে আছেন';

  @override
  String get liveStepArrived => 'পৌঁছেছেন';

  @override
  String get liveStepInProgress => 'কাজ চলছে';

  @override
  String get liveStepCompleted => 'সম্পন্ন';

  @override
  String liveAcceptedTitle(String name) {
    return '$name আপনার বুকিং গ্রহণ করেছেন';
  }

  @override
  String get liveAcceptedHint =>
      'তিনি শিগগিরই রওনা দেবেন। স্টার্ট কোড হাতের কাছে রাখুন।';

  @override
  String liveOnTheWayTitle(String name) {
    return '$name পথে আছেন';
  }

  @override
  String liveArrivedTitle(String name) {
    return '$name পৌঁছে গেছেন';
  }

  @override
  String get liveArrivedHint => 'কাজ শুরু করতে স্টার্ট কোডটি বলে দিন।';

  @override
  String get liveInProgressTitle => 'কাজ চলছে';

  @override
  String get liveInProgressHint =>
      'অতিরিক্ত আইটেম যোগ করার আগে আপনার অনুমোদন লাগবে।';

  @override
  String liveScheduledFor(String when) {
    return 'নির্ধারিত সময়: $when';
  }

  @override
  String get liveCodeTitle => 'স্টার্ট কোড';

  @override
  String get liveCodeHint => 'সেবাদাতা আপনার সামনে থাকলেই কেবল কোডটি জানান।';

  @override
  String liveCodeSemantics(String digits) {
    return 'স্টার্ট কোড $digits';
  }

  @override
  String get liveExtrasNoticeTitle => 'অনুমোদনের জন্য অতিরিক্ত আইটেম';

  @override
  String liveExtrasNoticeBody(String amount) {
    return 'আপনার সেবাদাতা $amount-এর আইটেম যোগ করেছেন।';
  }

  @override
  String get liveExtrasNoticeReview => 'দেখুন';

  @override
  String get liveCancel => 'বুকিং বাতিল করুন';

  @override
  String get liveReport => 'সমস্যা জানান';

  @override
  String get liveApprovalTitle => 'অতিরিক্ত আইটেম';

  @override
  String get liveApprovalHeading => 'আপনার সেবাদাতা আইটেম যোগ করেছেন';

  @override
  String get liveApprovalBody =>
      'দাম PAO নির্ধারিত। আপনার অনুমোদন ছাড়া কিছুই যোগ হবে না।';

  @override
  String get liveApprovalAdded => 'যোগ হবে';

  @override
  String get liveApprovalNewTotal => 'নতুন মোট';

  @override
  String get liveApprovalApprove => 'অনুমোদন দিন';

  @override
  String get liveApprovalDecline => 'প্রত্যাখ্যান করুন';

  @override
  String get liveApprovalNone => 'অনুমোদনের অপেক্ষায় কোনো অতিরিক্ত আইটেম নেই।';

  @override
  String get liveCompletedTitle => 'কাজ সম্পন্ন';

  @override
  String get liveCompletedHeading => 'সব কাজ শেষ!';

  @override
  String liveCompletedPay(String amount) {
    return 'নগদে $amount পরিশোধ করুন';
  }

  @override
  String liveCompletedPayBody(String name) {
    return '$name-কে নগদ টাকা দিন।';
  }

  @override
  String liveCompletedPaid(String amount) {
    return 'নগদে $amount পরিশোধ হয়েছে';
  }

  @override
  String liveCompletedRate(String name) {
    return '$name-কে রেটিং দিন';
  }

  @override
  String get liveCompletedReceipt => 'রসিদ দেখুন';

  @override
  String get cancelTitle => 'বুকিং বাতিল';

  @override
  String get cancelQuestion => 'কেন বাতিল করছেন?';

  @override
  String get cancelFree => 'কাজ শুরুর আগ পর্যন্ত বাতিল করা বিনামূল্যে।';

  @override
  String get cancelReasonChangedMind => 'আমি মত বদলেছি';

  @override
  String get cancelReasonOtherProvider => 'আমি অন্য সেবাদাতা পেয়েছি';

  @override
  String get cancelReasonLate => 'সেবাদাতা দেরি করছেন';

  @override
  String get cancelReasonMistake => 'ভুল করে বুক করেছি';

  @override
  String get cancelReasonOther => 'অন্য কারণ';

  @override
  String get cancelNote => 'আর কিছু বলবেন? (ঐচ্ছিক)';

  @override
  String get cancelConfirm => 'বুকিং বাতিল করুন';

  @override
  String get cancelKeep => 'বুকিং রাখুন';

  @override
  String get cancelDoneTitle => 'বুকিং বাতিল হয়েছে';

  @override
  String get cancelDoneBody =>
      'কোনো চার্জ নেই। যেকোনো সময় অন্য সেবাদাতা বুক করতে পারবেন।';

  @override
  String get cancelBookAgain => 'অন্য সেবাদাতা বুক করুন';

  @override
  String get cancelBlockedTitle => 'কাজ ইতিমধ্যে শুরু হয়ে গেছে';

  @override
  String get cancelBlockedBody =>
      'স্টার্ট কোড দেওয়ার পর বুকিং বাতিল করা যায় না। কোনো সমস্যা হলে জানান।';

  @override
  String get cancelClosedTitle => 'এই বুকিংটি আর সক্রিয় নেই';

  @override
  String get ratingTitle => 'সেবাদাতাকে রেটিং দিন';

  @override
  String ratingQuestion(String name) {
    return '$name-এর কাজ কেমন ছিল?';
  }

  @override
  String get ratingComment => 'অন্যদের আরও জানান (ঐচ্ছিক)';

  @override
  String get ratingSubmit => 'রেটিং জমা দিন';

  @override
  String get ratingSkip => 'এখন নয়';

  @override
  String get ratingTagOnTime => 'সময়মতো';

  @override
  String get ratingTagProfessional => 'পেশাদার';

  @override
  String get ratingTagQuality => 'মানসম্মত কাজ';

  @override
  String get ratingTagClean => 'পরিচ্ছন্ন';

  @override
  String get ratingTagFriendly => 'বন্ধুসুলভ';

  @override
  String get ratingTagFairPrice => 'ন্যায্য দাম';

  @override
  String get ratingTagLate => 'দেরি করেছেন';

  @override
  String get ratingTagRude => 'অভদ্র';

  @override
  String get ratingTagPoorQuality => 'নিম্নমানের কাজ';

  @override
  String get ratingTagMessy => 'অগোছালো';

  @override
  String get ratingThanksTitle => 'রেটিং দেওয়ার জন্য ধন্যবাদ!';

  @override
  String get ratingThanksBody =>
      'আপনার মতামত PAO-কে নিরাপদ ও নির্ভরযোগ্য রাখে।';

  @override
  String get ratingMyBookings => 'আমার বুকিং';

  @override
  String get connectivityStale =>
      'সর্বশেষ জানা অবস্থা দেখানো হচ্ছে। অনলাইনে ফিরলে আপডেট হবে।';

  @override
  String get connectivityCodeSaved =>
      'আপনি অফলাইনে আছেন। আপনার স্টার্ট কোড এই ফোনে সংরক্ষিত আছে।';
}
