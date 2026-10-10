// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'partner_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class PartnerL10nBn extends PartnerL10n {
  PartnerL10nBn([String locale = 'bn']) : super(locale);

  @override
  String get partnerTitle => 'পাও পার্টনার';

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
  String get jobsTitle => 'কাজ';

  @override
  String get jobsUpcoming => 'আসন্ন';

  @override
  String get jobsPast => 'আগের';

  @override
  String get jobsEmptyUpcoming => 'কোনো আসন্ন কাজ নেই';

  @override
  String get jobsEmptyPast => 'এখনো কোনো আগের কাজ নেই';

  @override
  String get jobsEmptyBody => 'কাজের অনুরোধ পেতে হোম থেকে অনলাইন হন।';

  @override
  String get jobsLoadMore => 'আরও দেখুন';

  @override
  String get jobsStatusRequested => 'অনুরোধ এসেছে';

  @override
  String get jobsStatusAccepted => 'গ্রহণ করা হয়েছে';

  @override
  String get jobsStatusOnTheWay => 'পথে আছেন';

  @override
  String get jobsStatusArrived => 'পৌঁছেছেন';

  @override
  String get jobsStatusInProgress => 'কাজ চলছে';

  @override
  String get jobsStatusCompleted => 'সম্পন্ন';

  @override
  String get jobsStatusRejected => 'প্রত্যাখ্যাত';

  @override
  String get jobsStatusTimedOut => 'মেয়াদ শেষ';

  @override
  String get jobsStatusCancelled => 'বাতিল';

  @override
  String get jobsDetailTitle => 'কাজের বিবরণ';

  @override
  String jobsCustomer(String name) {
    return 'গ্রাহক: $name';
  }

  @override
  String jobsArea(String area) {
    return 'এলাকা: $area';
  }

  @override
  String get jobsItems => 'আইটেম';

  @override
  String get jobsExtra => 'কাজের সময় যোগ করা';

  @override
  String get jobsTotal => 'মোট';

  @override
  String get jobsTimeline => 'সময়রেখা';

  @override
  String get jobsOpenLive => 'কাজ চালিয়ে যান';

  @override
  String get jobsReceipt => 'রসিদ দেখুন';

  @override
  String get jobsReceiptTitle => 'রসিদ';

  @override
  String get jobsPaidCash => 'নগদে পরিশোধিত';

  @override
  String get jobsReport => 'সমস্যা জানান';

  @override
  String get jobsReportTitle => 'সমস্যা জানান';

  @override
  String get jobsReportReason => 'কী সমস্যা হয়েছে?';

  @override
  String get jobsReasonCustomerUnavailable => 'গ্রাহক উপস্থিত নেই';

  @override
  String get jobsReasonPayment => 'পেমেন্টে সমস্যা';

  @override
  String get jobsReasonBehaviour => 'গ্রাহকের আচরণ';

  @override
  String get jobsReasonSafety => 'নিরাপত্তা নিয়ে উদ্বেগ';

  @override
  String get jobsReasonDamage => 'ক্ষতি';

  @override
  String get jobsReasonOther => 'অন্য কিছু';

  @override
  String get jobsReportNeedReason => 'একটি কারণ বেছে নিন।';

  @override
  String get jobsReportDescription => 'সমস্যাটি লিখুন';

  @override
  String get jobsReportDescriptionHint => 'কী হয়েছে এবং কখন?';

  @override
  String get jobsReportDescriptionInvalid =>
      '১০ থেকে ১০০০ অক্ষরের মধ্যে লিখুন।';

  @override
  String jobsReportPhotos(String count, String max) {
    return 'ছবি ($maxটির মধ্যে $countটি)';
  }

  @override
  String get jobsReportAddPhoto => 'ছবি যোগ করুন';

  @override
  String get jobsReportRemovePhoto => 'ছবি সরান';

  @override
  String get jobsReportSubmit => 'রিপোর্ট পাঠান';

  @override
  String get jobsReportSent => 'রিপোর্ট পাঠানো হয়েছে';

  @override
  String jobsReportTicket(String ticket) {
    return 'আপনার টিকিট নম্বর $ticket। আমাদের টিম আপনার সাথে যোগাযোগ করবে।';
  }

  @override
  String get jobsBackToJob => 'কাজে ফিরে যান';

  @override
  String get earnTitle => 'আয়';

  @override
  String get earnDay => 'আজ';

  @override
  String get earnWeek => 'এই সপ্তাহ';

  @override
  String get earnMonth => 'এই মাস';

  @override
  String earnJobs(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formattedটি কাজ',
    );
    return '$_temp0';
  }

  @override
  String get earnByJob => 'কাজ অনুযায়ী';

  @override
  String get earnEmptyTitle => 'এখনো কোনো আয় নেই';

  @override
  String get earnEmptyBody => 'সম্পন্ন কাজ ও আয় এখানে দেখা যাবে।';

  @override
  String get profTitle => 'প্রোফাইল';

  @override
  String get profChangePhoto => 'ছবি বদলান';

  @override
  String profLevelOf(String level, String name) {
    return 'লেভেল $level: $name';
  }

  @override
  String profRatingCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formattedটি রেটিং',
      zero: 'এখনো কোনো রেটিং নেই',
    );
    return '$_temp0';
  }

  @override
  String get profNoBio => 'গ্রাহকদের আপনার কাজ সম্পর্কে জানান।';

  @override
  String get profEditBio => 'পরিচিতি বদলান';

  @override
  String get profBioLabel => 'আপনার সম্পর্কে';

  @override
  String get profBioHint => 'আপনার দক্ষতা ও অভিজ্ঞতা';

  @override
  String get profBioTooLong => '৫০০ অক্ষরের মধ্যে লিখুন।';

  @override
  String get profBadgeNone => 'এখনো কোনো ব্যাজ নেই';

  @override
  String get profBadgeVerified => 'ভেরিফায়েড';

  @override
  String get profBadgeVerifiedPro => 'পাও ভেরিফায়েড প্রো';

  @override
  String get profLevel0 => 'নিবন্ধিত';

  @override
  String get profLevel1 => 'ডকুমেন্ট যাচাইকৃত';

  @override
  String get profLevel2 => 'দক্ষতা যাচাইকৃত';

  @override
  String get profLevel0How =>
      'সাইন আপ করে ফোন যাচাই করেছেন। এখনো বুকিং পাবেন না।';

  @override
  String get profLevel1How =>
      'সব ডকুমেন্ট পাও অনুমোদন করেছে। গ্রাহকরা \"ভেরিফায়েড\" দেখেন এবং আপনি বুকিং পান।';

  @override
  String get profLevel2How =>
      'পাও সরাসরি আপনার কাজ যাচাই করেছে। গ্রাহকরা \"পাও ভেরিফায়েড প্রো\" দেখেন এবং আপনি তালিকায় উপরে থাকেন।';

  @override
  String get profLevel2Title => 'লেভেল ২ দক্ষতা যাচাই';

  @override
  String get profLevel2Done => 'আপনি পাও ভেরিফায়েড প্রো।';

  @override
  String profLevel2Session(String when, String place) {
    return 'আপনার দক্ষতা যাচাই $when, স্থান: $place।';
  }

  @override
  String profLevel2Retry(String date) {
    return '$date এর পর আবার দক্ষতা যাচাই দিতে পারবেন।';
  }

  @override
  String get profLevel2Eligible =>
      'আপনি দক্ষতা যাচাইয়ের জন্য সময় নিতে পারেন। পাও সাপোর্টে কল করুন।';

  @override
  String get profLevel2NotYet =>
      'প্রথমে লেভেল ১ অর্জন করুন; তারপর পাও সরাসরি আপনার কাজ যাচাই করতে পারবে।';

  @override
  String get profPublicTitle => 'পাবলিক প্রোফাইল';

  @override
  String get profPublicHint =>
      'গ্রাহকরা আপনাকে এভাবে দেখেন। তারা কখনো আপনার ডকুমেন্ট বা ফোন নম্বর দেখেন না।';

  @override
  String profExperience(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted বছরের অভিজ্ঞতা',
      zero: 'এই পেশায় নতুন',
    );
    return '$_temp0';
  }

  @override
  String get profReviewsTitle => 'রিভিউ';

  @override
  String get profReviewsEmpty => 'এখনো কোনো রিভিউ নেই';

  @override
  String get profReviewsEmptyBody =>
      'প্রতিটি কাজ শেষে গ্রাহকরা রিভিউ দিতে পারেন।';

  @override
  String get profTagOnTime => 'সময়মতো';

  @override
  String get profTagProfessional => 'পেশাদার';

  @override
  String get profTagQualityWork => 'মানসম্মত কাজ';

  @override
  String get profTagClean => 'পরিচ্ছন্ন';

  @override
  String get profTagFriendly => 'বন্ধুসুলভ';

  @override
  String get profTagFairPrice => 'ন্যায্য দাম';

  @override
  String get profTagLate => 'দেরি';

  @override
  String get profTagRude => 'অভদ্র';

  @override
  String get profTagPoorQuality => 'নিম্নমানের কাজ';

  @override
  String get profTagMessy => 'অগোছালো';

  @override
  String get profTagPolite => 'ভদ্র';

  @override
  String get profTagClearInstructions => 'স্পষ্ট নির্দেশনা';

  @override
  String get profTagPaidPromptly => 'দ্রুত পরিশোধ';

  @override
  String get profTagSafePlace => 'নিরাপদ জায়গা';

  @override
  String get profTagUnclearInstructions => 'অস্পষ্ট নির্দেশনা';

  @override
  String get profTagUnsafePlace => 'অনিরাপদ জায়গা';

  @override
  String get profDocumentsTitle => 'ডকুমেন্ট';

  @override
  String get profDocumentsEmpty => 'এখনো কোনো ডকুমেন্ট নেই';

  @override
  String get profDocumentsUpdate => 'ডকুমেন্ট হালনাগাদ করুন';

  @override
  String get profItemNid => 'জাতীয় পরিচয়পত্র';

  @override
  String get profItemSelfie => 'লাইভ সেলফি';

  @override
  String get profItemPoliceClearance => 'পুলিশ ক্লিয়ারেন্স';

  @override
  String get profItemAddress => 'ঠিকানা';

  @override
  String get profItemEmergencyContact => 'জরুরি যোগাযোগ';

  @override
  String get profItemSkillProof => 'দক্ষতার প্রমাণ';

  @override
  String get profItemServiceArea => 'সেবা ও এলাকা';

  @override
  String get profItemCodeOfConduct => 'আচরণবিধি';

  @override
  String get profStatusMissing => 'জমা হয়নি';

  @override
  String get profStatusPending => 'যাচাই চলছে';

  @override
  String get profStatusApproved => 'অনুমোদিত';

  @override
  String get profStatusRejected => 'প্রত্যাখ্যাত';

  @override
  String get profStatusExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String profValidUntil(String date) {
    return '$date পর্যন্ত বৈধ';
  }

  @override
  String profExpiresSoon(String date) {
    return '$date তারিখে মেয়াদ শেষ। বুকিং পেতে দ্রুত নবায়ন করুন।';
  }

  @override
  String profExpired(String date) {
    return '$date তারিখে মেয়াদ শেষ হয়েছে। নবায়ন না করা পর্যন্ত বুকিং বন্ধ থাকবে।';
  }

  @override
  String get profLevelTitle => 'ব্যাজ ও লেভেল';

  @override
  String get profServicesTitle => 'সেবা ও এলাকা';

  @override
  String profServicesPick(String max) {
    return 'আপনার সেবা (সর্বোচ্চ $maxটি)';
  }

  @override
  String get profExperienceLabel => 'অভিজ্ঞতা (বছর)';

  @override
  String get profRadius => 'কতদূর পর্যন্ত যাবেন';

  @override
  String profRadiusKm(String km) {
    return '$km কিমি';
  }

  @override
  String get profHomeBase => 'আপনার অবস্থান';

  @override
  String get profHomeBaseSet => 'সেট করা আছে';

  @override
  String get profHomeBaseMissing => 'সেট করা হয়নি';

  @override
  String get profUseLocation => 'আমার লোকেশন নিন';

  @override
  String get profLocationOff => 'লোকেশন চালু করে আবার চেষ্টা করুন।';

  @override
  String get profSaved => 'সংরক্ষিত হয়েছে';

  @override
  String get profLanguageTitle => 'ভাষা';

  @override
  String get profLanguageBody =>
      'অ্যাপ, নোটিফিকেশন ও পাওর বার্তার ভাষা বেছে নিন।';

  @override
  String profLanguageNotSynced(String reason) {
    return 'এই ফোনে সংরক্ষিত, কিন্তু প্রোফাইলে নয়: $reason';
  }

  @override
  String get profHelpTitle => 'সাহায্য';

  @override
  String get profHelpJobsQ => 'কীভাবে কাজ পাব?';

  @override
  String get profHelpJobsA =>
      'হোম থেকে অনলাইন হন। কাছের গ্রাহকদের অনুরোধ কাউন্টডাউনসহ আসবে; সময় শেষের আগে গ্রহণ করুন।';

  @override
  String get profHelpCodeQ => 'স্টার্ট কোড কী?';

  @override
  String get profHelpCodeA =>
      'পৌঁছে গ্রাহকের কাছ থেকে ৪ সংখ্যার কোডটি নিন। কোড দেওয়ার পরই কাজ শুরু হয়।';

  @override
  String get profHelpCashQ => 'কীভাবে টাকা পাব?';

  @override
  String get profHelpCashA =>
      'কাজ শেষে গ্রাহক নগদে টাকা দেন। কাজ সম্পন্ন করতে অ্যাপে নগদ প্রাপ্তি নিশ্চিত করুন।';

  @override
  String get profHelpDocumentsQ => 'আমার বুকিং কেন বন্ধ হলো?';

  @override
  String get profHelpDocumentsA =>
      'পুলিশ ক্লিয়ারেন্সের মতো কোনো ডকুমেন্টের মেয়াদ শেষ হলে বুকিং বন্ধ থাকে। ডকুমেন্ট থেকে নতুনটি আপলোড করুন।';

  @override
  String get profHelpLevelQ => 'কীভাবে পাও ভেরিফায়েড প্রো হব?';

  @override
  String get profHelpLevelA =>
      'লেভেল ১ এর পর পাও সরাসরি আপনার কাজ যাচাই করতে পারে। পাস করলে লেভেল ২ এবং বেশি বুকিং পাবেন।';

  @override
  String get profHelpStillStuck =>
      'আরও সাহায্য দরকার? আমাদের টিম ফোনে সাহায্য করবে।';

  @override
  String get profHelpCall => 'পাও সাপোর্টে কল করুন';

  @override
  String get profLogOut => 'লগ আউট';

  @override
  String get profLogOutTitle => 'লগ আউট করবেন?';

  @override
  String get profLogOutBody =>
      'আবার সাইন ইন না করা পর্যন্ত এই ফোনে কাজের অনুরোধ পাবেন না।';
}
