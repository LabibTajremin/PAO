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
  String get onbTagline => 'নিজের মতো করে কাজ করুন';

  @override
  String get onbLanguage => 'ভাষা';

  @override
  String get onbSkip => 'এড়িয়ে যান';

  @override
  String get onbNext => 'পরবর্তী';

  @override
  String get onbStart => 'শুরু করুন';

  @override
  String get onbSlide1Title => 'কাছাকাছি কাজ পান';

  @override
  String get onbSlide1Body =>
      'আশেপাশের গ্রাহকেরা আপনার সেবা বুক করেন। আপনার সুবিধামতো কাজ গ্রহণ করুন।';

  @override
  String get onbSlide2Title => 'নির্দিষ্ট দাম, হাতে হাতে নগদ';

  @override
  String get onbSlide2Body =>
      'দাম ঠিক করে দেয় পাও, তাই দরদাম করতে হয় না। কাজ শেষে গ্রাহক আপনাকে নগদে টাকা দেন।';

  @override
  String get onbSlide3Title => 'যাচাইকৃত ও বিশ্বস্ত';

  @override
  String get onbSlide3Body =>
      'একবার কাগজপত্র যাচাই করে ভেরিফায়েড ব্যাজ পান এবং কাজের অনুরোধ পেতে শুরু করুন।';

  @override
  String get enrolTitle => 'নিবন্ধন';

  @override
  String enrolStepOf(int current, int total) {
    return 'ধাপ $current/$total';
  }

  @override
  String get enrolStepPersonal => 'ব্যক্তিগত তথ্য';

  @override
  String get enrolStepServices => 'আপনার সেবা';

  @override
  String get enrolStepArea => 'সেবার এলাকা';

  @override
  String get enrolStepNid => 'জাতীয় পরিচয়পত্র';

  @override
  String get enrolStepSelfie => 'লাইভ সেলফি';

  @override
  String get enrolStepPolice => 'পুলিশ ক্লিয়ারেন্স';

  @override
  String get enrolStepSkill => 'দক্ষতার প্রমাণ';

  @override
  String get enrolStepContact => 'জরুরি যোগাযোগ';

  @override
  String get enrolStepConduct => 'আচরণবিধি';

  @override
  String get enrolReviewTitle => 'দেখে নিয়ে জমা দিন';

  @override
  String get enrolSaveContinue => 'সংরক্ষণ করে এগিয়ে যান';

  @override
  String get enrolSkip => 'এখন এড়িয়ে যান';

  @override
  String get enrolPickDate => 'তারিখ বেছে নিন';

  @override
  String get enrolNameLabel => 'পূর্ণ নাম (এনআইডি অনুযায়ী)';

  @override
  String get enrolNameError =>
      'এনআইডিতে যেভাবে লেখা আছে সেভাবে পূর্ণ নাম লিখুন।';

  @override
  String get enrolDobLabel => 'জন্ম তারিখ';

  @override
  String get enrolDobError => 'আপনার বয়স কমপক্ষে ১৮ বছর হতে হবে।';

  @override
  String get enrolGenderLabel => 'লিঙ্গ';

  @override
  String get enrolGenderFemale => 'নারী';

  @override
  String get enrolGenderMale => 'পুরুষ';

  @override
  String get enrolGenderOther => 'অন্যান্য';

  @override
  String get enrolGenderError => 'আপনার লিঙ্গ বেছে নিন।';

  @override
  String get enrolPresentAddress => 'বর্তমান ঠিকানা';

  @override
  String get enrolPermanentAddress => 'স্থায়ী ঠিকানা';

  @override
  String get enrolAddressError => 'পূর্ণ ঠিকানা লিখুন।';

  @override
  String get enrolServicesHint =>
      'আপনি যে সেবা দেন তার মধ্যে সর্বোচ্চ ৫টি বেছে নিন।';

  @override
  String get enrolServicesError => 'কমপক্ষে একটি সেবা বেছে নিন।';

  @override
  String get enrolServicesEmpty => 'এখনো নিবন্ধনের জন্য কোনো সেবা খোলা নেই।';

  @override
  String get enrolExperience => 'অভিজ্ঞতা (বছর)';

  @override
  String get enrolAreaHint =>
      'আপনার মূল অবস্থান ঠিক করুন। কাজের পরিধির মধ্যে অনুরোধ পাবেন।';

  @override
  String get enrolAreaLocate => 'আমার বর্তমান অবস্থান ব্যবহার করুন';

  @override
  String get enrolAreaNoPin => 'এখনো অবস্থান ঠিক করা হয়নি';

  @override
  String enrolAreaPinned(String lat, String lng) {
    return 'মূল অবস্থান: $lat, $lng';
  }

  @override
  String get enrolAreaOff =>
      'লোকেশন চালু করুন এবং পাও পার্টনারকে তা ব্যবহারের অনুমতি দিন।';

  @override
  String get enrolAreaError => 'আগে আপনার মূল অবস্থান ঠিক করুন।';

  @override
  String enrolAreaRadius(int km) {
    return 'কাজের পরিধি: $km কিমি';
  }

  @override
  String get enrolNidNumber => 'এনআইডি নম্বর';

  @override
  String get enrolNidError => '১০, ১৩ বা ১৭ সংখ্যার এনআইডি নম্বর লিখুন।';

  @override
  String get enrolNidFront => 'কার্ডের সামনের দিক';

  @override
  String get enrolNidBack => 'কার্ডের পেছনের দিক';

  @override
  String get enrolPhotoError => 'এগিয়ে যাওয়ার আগে সব ছবি যোগ করুন।';

  @override
  String get enrolTakePhoto => 'ছবি তুলুন';

  @override
  String get enrolChoosePhoto => 'গ্যালারি থেকে বেছে নিন';

  @override
  String get enrolRetake => 'আবার তুলুন';

  @override
  String enrolUploading(int percent) {
    return 'আপলোড হচ্ছে $percent%';
  }

  @override
  String get enrolUploaded => 'আপলোড হয়েছে';

  @override
  String get enrolUploadFailed => 'আপলোড হয়নি।';

  @override
  String get enrolSelfieHint =>
      'ভালো আলোতে ফোনটি চোখের সমান উচ্চতায় ধরুন, সানগ্লাস বা টুপি খুলে ক্যামেরার দিকে তাকান।';

  @override
  String get enrolPoliceHint =>
      'আপনার পুলিশ ক্লিয়ারেন্স সনদ যোগ করুন। এটি গত ১২ মাসের মধ্যে ইস্যু হতে হবে।';

  @override
  String get enrolIssueDate => 'ইস্যুর তারিখ';

  @override
  String get enrolIssueDateError => 'ইস্যুর তারিখ দিন।';

  @override
  String get enrolSkillHint =>
      'ঐচ্ছিক: প্রশিক্ষণের সনদ বা আপনার কাজের ছবি যোগ করুন। এগুলো লেভেল ২ পেতে সাহায্য করে।';

  @override
  String enrolSkillPhoto(int number) {
    return 'ছবি $number';
  }

  @override
  String get enrolContactHint =>
      'জরুরি প্রয়োজনে আমরা যাকে ফোন করতে পারি। নিশ্চিত করতে তাকে একটি কোড পাঠানো হবে।';

  @override
  String get enrolContactName => 'নাম';

  @override
  String get enrolContactRelation => 'সম্পর্ক';

  @override
  String get enrolContactPhone => 'মোবাইল নম্বর';

  @override
  String get enrolContactNameError => 'তার নাম লিখুন।';

  @override
  String get enrolContactRelationError => 'আপনার সাথে সম্পর্ক লিখুন।';

  @override
  String get enrolContactPhoneError => '১১ সংখ্যার বাংলাদেশি মোবাইল নম্বর দিন।';

  @override
  String get enrolContactSendCode => 'কোড পাঠান';

  @override
  String enrolContactCodeSent(String phone) {
    return '$phone নম্বরে পাঠানো কোডটি দিন।';
  }

  @override
  String get enrolContactResend => 'আবার কোড পাঠান';

  @override
  String get enrolContactChange => 'যোগাযোগ বদলান';

  @override
  String get enrolConductIntro => 'পাও পার্টনার হিসেবে আমি:';

  @override
  String get enrolConductRule1 =>
      'প্রত্যেক গ্রাহকের সাথে সম্মানজনক আচরণ করব এবং তাদের বাড়ি ও জিনিসপত্র নিরাপদ রাখব।';

  @override
  String get enrolConductRule2 => 'সময়মতো পৌঁছাব এবং দেরি হলে গ্রাহককে জানাব।';

  @override
  String get enrolConductRule3 => 'অ্যাপে দেখানো দামের বেশি নেব না।';

  @override
  String get enrolConductRule4 =>
      'গ্রাহকের কাছে কখনো সুবিধা, বাড়তি টাকা বা পাও-এর বাইরে যোগাযোগ চাইব না।';

  @override
  String get enrolConductRule5 => 'মদ বা মাদকের প্রভাবে কখনো কাজ করব না।';

  @override
  String get enrolConductAccept => 'আমি আচরণবিধি পড়েছি এবং মেনে নিচ্ছি।';

  @override
  String get enrolReviewBody =>
      'সব ধাপ সম্পূর্ণ হয়েছে কিনা দেখে যাচাইয়ের জন্য জমা দিন।';

  @override
  String get enrolSubmittedBody => 'আপনার নিবন্ধন জমা দেওয়া হয়েছে।';

  @override
  String get enrolSubmit => 'যাচাইয়ের জন্য জমা দিন';

  @override
  String get enrolGoVerification => 'যাচাইয়ের অবস্থা দেখুন';

  @override
  String get enrolStepDone => 'সম্পন্ন';

  @override
  String get enrolStepTodo => 'বাকি';

  @override
  String get enrolOptional => 'ঐচ্ছিক';

  @override
  String get verifTitle => 'যাচাই';

  @override
  String verifLevel(int level) {
    return 'লেভেল $level';
  }

  @override
  String get verifBadgeNone => 'এখনো যাচাই হয়নি';

  @override
  String get verifBadgeVerified => 'ভেরিফায়েড';

  @override
  String get verifBadgePro => 'পাও ভেরিফায়েড প্রো';

  @override
  String get verifCleared => 'আপনি যাচাইকৃত এবং বুকিং পেতে পারেন।';

  @override
  String get verifIncomplete => 'আপনার কাগজপত্র যাচাই করতে নিবন্ধন শেষ করুন।';

  @override
  String get verifAttention => 'কিছু তথ্য ঠিক করতে হবে। নিচে আবার আপলোড করুন।';

  @override
  String get verifPending =>
      'আমরা আপনার কাগজপত্র যাচাই করছি। সাধারণত ৪৮ ঘণ্টা পর্যন্ত সময় লাগে।';

  @override
  String get verifGoHome => 'হোমে যান';

  @override
  String get verifContinue => 'নিবন্ধন চালিয়ে যান';

  @override
  String get verifSubmit => 'দেখে নিয়ে জমা দিন';

  @override
  String get verifItemsTitle => 'কাগজপত্র';

  @override
  String get verifNoItems => 'এখনো কোনো কাগজপত্র নেই।';

  @override
  String get verifItemNid => 'জাতীয় পরিচয়পত্র';

  @override
  String get verifItemSelfie => 'লাইভ সেলফি';

  @override
  String get verifItemPolice => 'পুলিশ ক্লিয়ারেন্স';

  @override
  String get verifItemAddress => 'ঠিকানা';

  @override
  String get verifItemContact => 'জরুরি যোগাযোগ';

  @override
  String get verifItemSkill => 'দক্ষতার প্রমাণ';

  @override
  String get verifItemArea => 'সেবা ও এলাকা';

  @override
  String get verifItemConduct => 'আচরণবিধি';

  @override
  String get verifStatusMissing => 'দেওয়া হয়নি';

  @override
  String get verifStatusPending => 'যাচাই চলছে';

  @override
  String get verifStatusApproved => 'অনুমোদিত';

  @override
  String get verifStatusRejected => 'বাতিল';

  @override
  String get verifStatusExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String verifReason(String reason) {
    return 'কারণ: $reason';
  }

  @override
  String verifExpires(String date) {
    return '$date পর্যন্ত বৈধ';
  }

  @override
  String verifExpired(String date) {
    return '$date তারিখে মেয়াদ শেষ হয়েছে';
  }

  @override
  String get verifReupload => 'আবার আপলোড করুন';

  @override
  String get verifLevel2Title => 'লেভেল ২: দক্ষতা যাচাই';

  @override
  String get verifLevel2Eligible =>
      'পাও ভেরিফায়েড প্রো পেতে আপনি দক্ষতা যাচাইয়ে অংশ নিতে পারেন। সময় ঠিক করতে আমাদের টিম আপনার সাথে যোগাযোগ করবে।';

  @override
  String get verifLevel2NotEligible =>
      'আগে লেভেল ১ অর্জন করুন, তারপর দক্ষতা যাচাইয়ে অংশ নিতে পারবেন।';

  @override
  String verifLevel2Session(String date, String place) {
    return 'দক্ষতা যাচাই: $date, $place';
  }

  @override
  String verifLevel2Retry(String date) {
    return '$date এর পর আবার চেষ্টা করতে পারবেন।';
  }

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
