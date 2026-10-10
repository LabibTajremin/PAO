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
  String get bookingsTitle => 'আমার বুকিং';

  @override
  String get bookingsUpcoming => 'আসন্ন';

  @override
  String get bookingsPast => 'আগের';

  @override
  String get bookingsEmptyUpcoming => 'কোনো আসন্ন বুকিং নেই';

  @override
  String get bookingsEmptyUpcomingBody =>
      'যাচাইকৃত একজন সেবাদাতা বুক করুন, বুকিংটি এখানে দেখা যাবে।';

  @override
  String get bookingsEmptyPast => 'এখনো কোনো আগের বুকিং নেই';

  @override
  String get bookingsEmptyPastBody =>
      'শেষ হওয়া ও বাতিল বুকিং এখানে দেখা যাবে।';

  @override
  String get bookingsBookService => 'সেবা বুক করুন';

  @override
  String get bookingsStatusRequested => 'উত্তরের অপেক্ষায়';

  @override
  String get bookingsStatusAccepted => 'গ্রহণ করা হয়েছে';

  @override
  String get bookingsStatusOnTheWay => 'পথে আছেন';

  @override
  String get bookingsStatusArrived => 'পৌঁছেছেন';

  @override
  String get bookingsStatusInProgress => 'কাজ চলছে';

  @override
  String get bookingsStatusCompleted => 'সম্পন্ন';

  @override
  String get bookingsStatusRejected => 'গ্রহণ করেননি';

  @override
  String get bookingsStatusTimedOut => 'সাড়া মেলেনি';

  @override
  String get bookingsStatusCancelled => 'বাতিল';

  @override
  String get bookingsDetailTitle => 'বুকিংয়ের বিস্তারিত';

  @override
  String get bookingsProvider => 'আপনার সেবাদাতা';

  @override
  String get bookingsCallProvider => 'সেবাদাতাকে কল করুন';

  @override
  String bookingsRatingSummary(String rating, String count) {
    return '$rating রেটিং · $countটি রিভিউ';
  }

  @override
  String get bookingsAddress => 'ঠিকানা';

  @override
  String get bookingsNote => 'আপনার নোট';

  @override
  String get bookingsTimeline => 'সময়রেখা';

  @override
  String get bookingsBill => 'বিল';

  @override
  String get bookingsExtra => 'কাজের সময় যোগ করা';

  @override
  String get bookingsTotal => 'মোট';

  @override
  String get bookingsPayCash => 'কাজ শেষে সেবাদাতাকে নগদে পরিশোধ করুন।';

  @override
  String get bookingsPaidCash => 'নগদে পরিশোধিত';

  @override
  String get bookingsTrack => 'লাইভ দেখুন';

  @override
  String get bookingsWaiting => 'অনুরোধের অবস্থা দেখুন';

  @override
  String get bookingsReceipt => 'রসিদ দেখুন';

  @override
  String get bookingsRate => 'সেবাদাতাকে রেটিং দিন';

  @override
  String get bookingsBookAgain => 'আবার বুক করুন';

  @override
  String get bookingsReport => 'সমস্যা জানান';

  @override
  String get bookingsCancelledTitle => 'বুকিংটি বাতিল হয়েছে';

  @override
  String get bookingsRejectedTitle => 'সেবাদাতা বুকিংটি গ্রহণ করেননি';

  @override
  String get bookingsTimedOutTitle => 'সেবাদাতা সময়মতো সাড়া দেননি';

  @override
  String get bookingsCancelledByYou => 'আপনি এটি বাতিল করেছেন।';

  @override
  String get bookingsCancelledByProvider => 'সেবাদাতা এটি বাতিল করেছেন।';

  @override
  String get bookingsCancelledByPao => 'PAO এটি বাতিল করেছে।';

  @override
  String bookingsEndedReason(String reason) {
    return 'কারণ: $reason';
  }

  @override
  String get bookingsNoCharge => 'আপনার কাছ থেকে কোনো টাকা নেওয়া হয়নি।';

  @override
  String get bookingsReasonChangedMind => 'মত বদলেছি';

  @override
  String get bookingsReasonFoundOther => 'অন্য সেবাদাতা পেয়েছি';

  @override
  String get bookingsReasonProviderLate => 'সেবাদাতা দেরি করেছেন';

  @override
  String get bookingsReasonByMistake => 'ভুল করে বুক করেছি';

  @override
  String get bookingsReasonEmergency => 'সেবাদাতার জরুরি প্রয়োজন';

  @override
  String get bookingsReasonUnreachable => 'আপনার সাথে যোগাযোগ করা যায়নি';

  @override
  String get bookingsReasonUnsafe => 'জায়গাটি নিরাপদ মনে হয়নি';

  @override
  String get bookingsReasonBusy => 'সেবাদাতা ব্যস্ত ছিলেন';

  @override
  String get bookingsReasonTooFar => 'অনেক দূরে';

  @override
  String get bookingsReasonNotMyService => 'এই সেবা তিনি দেন না';

  @override
  String get bookingsReasonOther => 'অন্য কারণ';

  @override
  String get bookingsReceiptTitle => 'রসিদ';

  @override
  String bookingsReceiptNumber(String number) {
    return 'রসিদ $number';
  }

  @override
  String bookingsReceiptCompleted(String date) {
    return 'সম্পন্ন: $date';
  }

  @override
  String get bookingsReceiptService => 'সেবা';

  @override
  String get bookingsReceiptProvider => 'সেবাদাতা';

  @override
  String get bookingsReceiptCustomer => 'গ্রাহক';

  @override
  String get bookingsReceiptArea => 'এলাকা';

  @override
  String get bookingsReceiptThanks => 'PAO বেছে নেওয়ার জন্য ধন্যবাদ।';

  @override
  String get bookingsReceiptShare => 'PDF হিসেবে শেয়ার করুন';

  @override
  String get bookingsReceiptShareFailed =>
      'রসিদ শেয়ার করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get reportTitle => 'সমস্যা জানান';

  @override
  String get reportIntro =>
      'কী সমস্যা হয়েছে জানান। আমাদের সাপোর্ট টিম প্রতিটি অভিযোগ পড়ে।';

  @override
  String get reportReason => 'কী সমস্যা হয়েছে?';

  @override
  String get reportNeedReason => 'একটি কারণ বেছে নিন।';

  @override
  String get reportReasonNoShow => 'সেবাদাতা আসেননি';

  @override
  String get reportReasonLate => 'সেবাদাতা দেরি করেছেন';

  @override
  String get reportReasonPoorQuality => 'কাজের মান খারাপ';

  @override
  String get reportReasonOvercharge => 'নির্ধারিত দামের বেশি নিয়েছেন';

  @override
  String get reportReasonDamage => 'কিছু ক্ষতিগ্রস্ত হয়েছে';

  @override
  String get reportReasonBehaviour => 'অভদ্র বা অপেশাদার আচরণ';

  @override
  String get reportReasonSafety => 'নিরাপদ বোধ করিনি';

  @override
  String get reportReasonPayment => 'পরিশোধে সমস্যা';

  @override
  String get reportReasonOther => 'অন্য কিছু';

  @override
  String get reportDescription => 'সমস্যাটি লিখুন';

  @override
  String get reportDescriptionHint => 'কী হয়েছিল, কখন?';

  @override
  String get reportDescriptionInvalid => '১০ থেকে ১০০০ অক্ষরের মধ্যে লিখুন।';

  @override
  String reportPhotos(String count, String max) {
    return 'ছবি ($maxটির মধ্যে $countটি)';
  }

  @override
  String get reportTakePhoto => 'ছবি তুলুন';

  @override
  String get reportChoosePhoto => 'ছবি বেছে নিন';

  @override
  String get reportRemovePhoto => 'ছবি সরান';

  @override
  String get reportSubmit => 'অভিযোগ পাঠান';

  @override
  String get reportSent => 'অভিযোগ পাঠানো হয়েছে';

  @override
  String reportTicket(String ticket) {
    return 'আপনার টিকিট নম্বর $ticket। আমাদের টিম এটি দেখে আপনার সাথে যোগাযোগ করবে।';
  }

  @override
  String get reportBackToBooking => 'বুকিংয়ে ফিরে যান';

  @override
  String get notifReadAll => 'সব পড়া হয়েছে';

  @override
  String get notifEmpty => 'এখনো কোনো নোটিফিকেশন নেই';

  @override
  String get notifEmptyBody => 'আপনার বুকিংয়ের খবর এখানে আসবে।';

  @override
  String get notifUnread => 'পড়া হয়নি';

  @override
  String get accountEditProfile => 'প্রোফাইল সম্পাদনা';

  @override
  String get accountAddresses => 'সংরক্ষিত ঠিকানা';

  @override
  String get accountLanguage => 'ভাষা';

  @override
  String get accountHelp => 'সাহায্য ও সহায়তা';

  @override
  String get accountLegal => 'শর্তাবলি ও গোপনীয়তা';

  @override
  String get accountDelete => 'অ্যাকাউন্ট মুছুন';

  @override
  String get accountLogOut => 'লগ আউট';

  @override
  String get accountLogOutTitle => 'PAO থেকে লগ আউট করবেন?';

  @override
  String get accountLogOutBody => 'আবার সাইন ইন করতে ফোন নম্বর ও কোড লাগবে।';

  @override
  String get accountChangePhoto => 'ছবি বদলান';

  @override
  String get accountProfileSaved => 'প্রোফাইল সংরক্ষিত হয়েছে';

  @override
  String get accountAddressesEmpty => 'কোনো সংরক্ষিত ঠিকানা নেই';

  @override
  String get accountAddressesEmptyBody =>
      'দ্রুত বুক করতে বাসা বা অফিসের ঠিকানা সংরক্ষণ করুন।';

  @override
  String get accountAddressAdd => 'ঠিকানা যোগ করুন';

  @override
  String accountAddressLimit(String max) {
    return 'সর্বোচ্চ $maxটি ঠিকানা সংরক্ষণ করা যায়।';
  }

  @override
  String get accountAddressDefault => 'ডিফল্ট';

  @override
  String get accountAddressMakeDefault => 'ডিফল্ট করুন';

  @override
  String get accountAddressEdit => 'সম্পাদনা';

  @override
  String get accountAddressDelete => 'মুছুন';

  @override
  String get accountAddressDeleteTitle => 'ঠিকানাটি মুছবেন?';

  @override
  String get accountAddressDeleteBody =>
      'এটি আপনার সংরক্ষিত ঠিকানা থেকে সরিয়ে দেওয়া হবে।';

  @override
  String get accountAddressActions => 'ঠিকানার অপশন';

  @override
  String get accountAddressHome => 'বাসা';

  @override
  String get accountAddressOffice => 'অফিস';

  @override
  String get accountAddressOther => 'অন্যান্য';

  @override
  String get accountLanguageBody =>
      'অ্যাপ, নোটিফিকেশন ও এসএমএসের ভাষা বেছে নিন।';

  @override
  String accountLanguageNotSynced(String reason) {
    return 'এই ফোনে সংরক্ষিত হয়েছে, তবে প্রোফাইলে এখনো নয়: $reason';
  }

  @override
  String get accountHelpIntro => 'সাধারণ প্রশ্নের উত্তর';

  @override
  String get accountHelpBookQ => 'কীভাবে সেবা বুক করব?';

  @override
  String get accountHelpBookA =>
      'একটি সেবা বেছে নিন, কাছের যাচাইকৃত সেবাদাতা নির্বাচন করুন, তারপর সময় ও ঠিকানা নিশ্চিত করুন। সেবাদাতা কয়েক মিনিটের মধ্যে গ্রহণ করবেন।';

  @override
  String get accountHelpPayQ => 'কীভাবে পরিশোধ করব?';

  @override
  String get accountHelpPayA =>
      'কাজ শেষে সেবাদাতাকে নগদে দিন। বুকিংয়ের সময় দেখানো দাম এবং আপনার অনুমোদিত অতিরিক্ত কাজের দামই দেবেন।';

  @override
  String get accountHelpCodeQ => 'স্টার্ট কোড কী?';

  @override
  String get accountHelpCodeA =>
      'সেবাদাতা পৌঁছালে অ্যাপের ৪ সংখ্যার কোডটি তাঁকে বলুন। কোডটি দেওয়ার পরই কাজ শুরু হয়, তাই আপনি নিশ্চিত থাকেন সঠিক মানুষটি এসেছেন।';

  @override
  String get accountHelpCancelQ => 'বুকিং কি বাতিল করা যায়?';

  @override
  String get accountHelpCancelA =>
      'হ্যাঁ, কাজ শুরুর আগ পর্যন্ত। বুকিংটি খুলে বাতিল চাপুন এবং একটি কারণ বেছে নিন।';

  @override
  String get accountHelpProblemQ => 'কোনো সমস্যা হয়েছে, এখন কী করব?';

  @override
  String get accountHelpProblemA =>
      'বুকিংটি খুলে \"সমস্যা জানান\" চাপুন। আমাদের সাপোর্ট টিম প্রতিটি অভিযোগ দেখে।';

  @override
  String get accountHelpStillStuck =>
      'আরও সাহায্য লাগবে? আমাদের সাপোর্ট টিম আপনার পাশে আছে।';

  @override
  String get accountHelpCall => 'সাপোর্টে কল করুন';

  @override
  String get accountHelpEmail => 'সাপোর্টে ইমেইল করুন';

  @override
  String get accountHelpEmailSubject => 'PAO সহায়তার অনুরোধ';

  @override
  String get accountLegalTermsHeading => 'ব্যবহারের শর্তাবলি';

  @override
  String get accountLegalTermsBody =>
      'PAO আপনাকে স্বাধীন, যাচাইকৃত সেবাদাতাদের সাথে যুক্ত করে। দাম নির্দিষ্ট এবং বুক করার আগেই দেখানো হয়; অতিরিক্ত কাজের জন্য অ্যাপে আপনার অনুমোদন লাগে। কাজ শেষে সেবাদাতাকে নগদে পরিশোধ করবেন। সময়মতো ঠিকানায় থাকুন, সেবাদাতাদের সাথে সম্মানজনক আচরণ করুন এবং পরিকল্পনা বদলালে আগেভাগে বাতিল করুন। PAO-এর অপব্যবহার করলে অ্যাকাউন্ট স্থগিত হতে পারে।';

  @override
  String get accountLegalPrivacyHeading => 'গোপনীয়তা';

  @override
  String get accountLegalPrivacyBody =>
      'বুকিং পরিচালনার জন্য আমরা আপনার নাম, ফোন নম্বর, ছবি ও সংরক্ষিত ঠিকানা রাখি। সেবাদাতা বুকিং গ্রহণ করার পরেই কেবল আপনার সঠিক ঠিকানা ও ফোন নম্বর দেখতে পান। আপনি চাইলে তবেই আমরা আপনার অবস্থান ব্যবহার করি। আমরা কখনো আপনার তথ্য বিক্রি করি না।';

  @override
  String get accountLegalChoicesHeading => 'আপনার পছন্দ';

  @override
  String get accountLegalChoicesBody =>
      'যেকোনো সময় প্রোফাইল ও ভাষা বদলাতে পারেন, এবং অ্যাকাউন্ট ট্যাব থেকে অ্যাকাউন্ট মুছতে পারেন। মুছে ফেললে আপনার ব্যক্তিগত তথ্য সরিয়ে দেওয়া হয়; আগের বুকিংয়ের রেকর্ড সেগুলো ছাড়াই রাখা হয়।';

  @override
  String get accountDeleteHeading => 'যাওয়ার আগে জেনে নিন';

  @override
  String get accountDeleteBody =>
      'অ্যাকাউন্ট মুছলে আপনার নাম, ছবি, ফোন নম্বর ও সংরক্ষিত ঠিকানা মুছে যাবে এবং সব ডিভাইস থেকে সাইন আউট হবে। এটি আর ফেরানো যাবে না।';

  @override
  String get accountDeleteRecords =>
      'আগের বুকিংয়ের রেকর্ড আপনার ব্যক্তিগত তথ্য ছাড়া রাখা হবে।';

  @override
  String get accountDeleteSendCode => 'নিশ্চিতকরণ কোড পাঠান';

  @override
  String get accountDeleteCodeTitle => 'কোডটি লিখুন';

  @override
  String accountDeleteCodeBody(String phone) {
    return '$phone নম্বরে ৬ সংখ্যার একটি কোড পাঠানো হয়েছে। অ্যাকাউন্ট মুছতে কোডটি লিখুন।';
  }

  @override
  String get accountDeleteResend => 'নতুন কোড পাঠান';

  @override
  String get accountDeleteConfirm => 'আমার অ্যাকাউন্ট মুছুন';

  @override
  String get accountDeletedTitle => 'আপনার অ্যাকাউন্ট মুছে ফেলা হয়েছে';

  @override
  String get accountDeletedBody =>
      'PAO ব্যবহারের জন্য ধন্যবাদ। যেকোনো সময় ফোন নম্বর দিয়ে নতুন অ্যাকাউন্ট খুলতে পারবেন।';

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
