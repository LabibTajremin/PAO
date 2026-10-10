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
}
