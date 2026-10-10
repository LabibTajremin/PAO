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
  String get locPermTitle => 'আপনার কাছের সেবা খুঁজুন';

  @override
  String get locPermBody =>
      'ঠিকানা ঠিক করতে ও কাছের সেবাদাতা দেখাতে পাও একবার আপনার লোকেশন নেয়। আমরা কখনো আপনাকে পেছন থেকে ট্র্যাক করি না।';

  @override
  String get locPermAllow => 'লোকেশন ব্যবহারের অনুমতি দিন';

  @override
  String get locPermManual => 'নিজে ঠিকানা লিখুন';

  @override
  String get locTitleSet => 'আপনার লোকেশন ঠিক করুন';

  @override
  String get locTitleNew => 'ঠিকানা যোগ করুন';

  @override
  String get locTitleEdit => 'ঠিকানা সম্পাদনা';

  @override
  String get locUseCurrent => 'আমার বর্তমান লোকেশন ব্যবহার করুন';

  @override
  String get locLocateFailed =>
      'আপনার লোকেশন পাওয়া যায়নি। ঠিকানা খুঁজুন বা পিন সরান।';

  @override
  String get locDragHint => 'পিন সরাতে ম্যাপ টেনে নিন';

  @override
  String get locPinHere => 'আপনার পিন';

  @override
  String get locSearch => 'ঠিকানা খুঁজুন';

  @override
  String get locSearchHint => 'রাস্তা, এলাকা বা পরিচিত স্থান';

  @override
  String get locLabel => 'যে নামে সংরক্ষণ করবেন';

  @override
  String get locLabelHome => 'বাসা';

  @override
  String get locLabelOffice => 'অফিস';

  @override
  String get locLabelOther => 'অন্যান্য';

  @override
  String get locLine1 => 'বাড়ি ও রাস্তা';

  @override
  String get locLine1Hint => 'বাড়ি ১২, রোড ৫, ব্লক সি';

  @override
  String get locLine1Invalid => '৩ থেকে ২০০ অক্ষর লিখুন।';

  @override
  String get locLine2 => 'তলা, ফ্ল্যাট বা পরিচিত স্থান (ঐচ্ছিক)';

  @override
  String get locArea => 'এলাকা';

  @override
  String get locSave => 'ঠিকানা সংরক্ষণ করুন';

  @override
  String locCovered(String area) {
    return '$area এলাকায় পাও সেবা দেয়';
  }

  @override
  String get locNotCoveredTitle => 'আমরা এখনো এখানে পৌঁছাইনি';

  @override
  String get locNotCoveredBody =>
      'এই জায়গায় এখনো পাও চালু হয়নি। ঠিকানাটি সংরক্ষণ করে রাখতে পারেন, আমরা এলে বুক করতে পারবেন।';

  @override
  String get homeAddressTitle => 'আপনার ঠিকানা';

  @override
  String get homeNoAddress => 'ঠিকানা ঠিক করুন';

  @override
  String get homeNoAddressBody => 'কাছের সেবা দেখতে আপনার ঠিকানা যোগ করুন।';

  @override
  String get homeSearchHint => 'সেবা খুঁজুন';

  @override
  String get homeCategories => 'সেবাসমূহ';

  @override
  String get homeAllServices => 'সব সেবা';

  @override
  String get homeNoServices => 'এখনো কোনো সেবা নেই';

  @override
  String get homeAddressSheet => 'ঠিকানা বেছে নিন';

  @override
  String get homeAddAddress => 'নতুন ঠিকানা যোগ করুন';

  @override
  String get homeNotCoveredBody =>
      'এই ঠিকানায় এখনো পাও চালু হয়নি। সেবা দেখতে অন্য ঠিকানা বেছে নিন।';

  @override
  String get homeChangeAddress => 'ঠিকানা বদলান';

  @override
  String get homeActiveOpen => 'দেখুন';

  @override
  String get homeStatusRequested => 'সেবাদাতার সম্মতির অপেক্ষায়';

  @override
  String get homeStatusAccepted => 'সেবাদাতা সম্মতি দিয়েছেন';

  @override
  String get homeStatusOnTheWay => 'সেবাদাতা পথে আছেন';

  @override
  String get homeStatusArrived => 'সেবাদাতা পৌঁছে গেছেন';

  @override
  String get homeStatusInProgress => 'কাজ চলছে';

  @override
  String get searchHint => 'সেবা খুঁজুন, যেমন ফ্যান মেরামত';

  @override
  String get searchPrompt => 'কী ধরনের সাহায্য দরকার?';

  @override
  String get searchServices => 'সেবা';

  @override
  String get searchSubServices => 'নির্দিষ্ট কাজ';

  @override
  String searchNoResults(String query) {
    return '\"$query\"-এর কোনো ফলাফল নেই';
  }

  @override
  String get searchNoResultsBody =>
      'বানান দেখে নিন বা অন্য শব্দে খুঁজুন। সব সেবাও দেখতে পারেন।';

  @override
  String get svcPerJob => 'প্রতি কাজ';

  @override
  String get svcPerUnit => 'প্রতি ইউনিট';

  @override
  String get svcPerHour => 'প্রতি ঘণ্টা';

  @override
  String get svcPerDay => 'প্রতি দিন';

  @override
  String get svcIncluded => 'যা অন্তর্ভুক্ত';

  @override
  String get svcExcluded => 'যা অন্তর্ভুক্ত নয়';

  @override
  String get svcTotal => 'মোট';

  @override
  String get svcChooseHint => 'এগোতে অন্তত একটি কাজ বেছে নিন।';

  @override
  String get svcWomenOnly => 'এই সেবা শুধু নারী সেবাদাতারা দেন।';

  @override
  String get svcSeeProviders => 'সেবাদাতা দেখুন';

  @override
  String get svcFixedPrice => 'দাম পাও নির্ধারিত। কাজ শেষে নগদে পরিশোধ করুন।';

  @override
  String get svcNoItems => 'এই সেবায় এখনো বুক করার মতো কিছু নেই।';

  @override
  String get svcHireStart => 'শুরু';

  @override
  String get svcHireDate => 'তারিখ বেছে নিন';

  @override
  String get svcHireTime => 'সময় বেছে নিন';

  @override
  String get svcHireDuty => 'ডিউটি';

  @override
  String get svcHireStartPast => 'ভবিষ্যতের কোনো সময় বেছে নিন।';

  @override
  String get svcHireNeedStart => 'ড্রাইভার কখন শুরু করবেন তা বেছে নিন।';

  @override
  String svcHours(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n ঘণ্টা',
    );
    return '$_temp0';
  }

  @override
  String svcDays(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n দিন',
    );
    return '$_temp0';
  }

  @override
  String get provTitle => 'আপনার কাছের সেবাদাতা';

  @override
  String get provSortFilter => 'সাজান ও ফিল্টার';

  @override
  String get provSort => 'যেভাবে সাজাবেন';

  @override
  String get provSortDistance => 'সবচেয়ে কাছে';

  @override
  String get provSortRating => 'সেরা রেটিং';

  @override
  String get provFilter => 'শুধু দেখান';

  @override
  String get provFilterTopRated => '৪ তারকা ও তার বেশি';

  @override
  String get provFilterPro => 'পাও ভেরিফায়েড প্রো';

  @override
  String get provApply => 'প্রয়োগ করুন';

  @override
  String get provEmptyTitle => 'এই মুহূর্তে কাছে কোনো সেবাদাতা নেই';

  @override
  String get provEmptyBody =>
      'সারা দিনই সেবাদাতারা অনলাইনে আসেন। কিছুক্ষণ পর আবার দেখুন বা ফিল্টার বদলান।';

  @override
  String get provNoAddressTitle => 'আগে আপনার ঠিকানা যোগ করুন';

  @override
  String get provNoAddressBody => 'কাছের সেবাদাতা খুঁজতে আপনার ঠিকানা দরকার।';

  @override
  String get provNoDraft => 'আগে সেবার পাতায় কী দরকার তা বেছে নিন।';

  @override
  String get provChooseItems => 'কাজ বেছে নিন';

  @override
  String get provPriceFor => 'আপনার বাছাইয়ের দাম';

  @override
  String provJobs(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$nটি কাজ সম্পন্ন',
    );
    return '$_temp0';
  }

  @override
  String provKmAway(String km) {
    return '$km কিমি দূরে';
  }

  @override
  String provMAway(String m) {
    return '$m মিটার দূরে';
  }

  @override
  String get provBadgeNone => 'যাচাই হয়নি';

  @override
  String get provBadgeVerified => 'যাচাইকৃত';

  @override
  String get provBadgeVerifiedPro => 'পাও ভেরিফায়েড প্রো';

  @override
  String get provBadgeWhat => 'ব্যাজের মানে কী?';

  @override
  String get provBadgeSheet => 'ব্যাজ সম্পর্কে';

  @override
  String get provBadgeVerifiedBody =>
      'পাও-এর যাচাইকারী তাদের এনআইডি, সেলফি, পুলিশ ক্লিয়ারেন্স, ঠিকানা ও জরুরি যোগাযোগ যাচাই করেছেন।';

  @override
  String get provBadgeProBody =>
      'যাচাইকৃত, এবং পাও সরাসরি দক্ষতা পরীক্ষা বা তত্ত্বাবধানে কাজের মাধ্যমে তাদের কাজও যাচাই করেছে। প্রো সেবাদাতারা তালিকায় ওপরে থাকেন।';

  @override
  String provExperience(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n বছরের অভিজ্ঞতা',
    );
    return '$_temp0';
  }

  @override
  String provMemberSince(String date) {
    return '$date থেকে পাও-তে';
  }

  @override
  String get provServices => 'সেবাসমূহ';

  @override
  String get provRatings => 'রেটিং';

  @override
  String provRatingCount(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$nটি রেটিং',
      zero: 'এখনো কোনো রেটিং নেই',
    );
    return '$_temp0';
  }

  @override
  String get provReviews => 'সাম্প্রতিক রিভিউ';

  @override
  String get provAllReviews => 'সব রিভিউ';

  @override
  String get provNoReviews => 'এখনো কোনো রিভিউ নেই';

  @override
  String get provNoReviewsBody => 'কাজ শেষ হলে এখানে রিভিউ দেখা যাবে।';

  @override
  String provBook(String name) {
    return '$name-কে বুক করুন';
  }

  @override
  String get provAbout => 'পরিচিতি';

  @override
  String get provTagOnTime => 'সময়মতো';

  @override
  String get provTagProfessional => 'পেশাদার';

  @override
  String get provTagQualityWork => 'মানসম্মত কাজ';

  @override
  String get provTagClean => 'পরিচ্ছন্ন';

  @override
  String get provTagFriendly => 'বন্ধুসুলভ';

  @override
  String get provTagFairPrice => 'ন্যায্য দাম';

  @override
  String get provTagLate => 'দেরিতে এসেছেন';

  @override
  String get provTagRude => 'অভদ্র';

  @override
  String get provTagPoorQuality => 'নিম্নমানের কাজ';

  @override
  String get provTagMessy => 'অগোছালো';

  @override
  String get provTagPolite => 'ভদ্র';

  @override
  String get provTagClearInstructions => 'স্পষ্ট নির্দেশনা';

  @override
  String get provTagPaidPromptly => 'সময়মতো পরিশোধ';

  @override
  String get provTagSafePlace => 'নিরাপদ জায়গা';

  @override
  String get provTagUnclearInstructions => 'অস্পষ্ট নির্দেশনা';

  @override
  String get provTagUnsafePlace => 'অনিরাপদ জায়গা';
}
