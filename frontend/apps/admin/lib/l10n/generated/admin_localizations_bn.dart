// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AdminL10nBn extends AdminL10n {
  AdminL10nBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'পাও অ্যাডমিন';

  @override
  String get navDashboard => 'ড্যাশবোর্ড';

  @override
  String get navVerification => 'যাচাই';

  @override
  String get navLevel2 => 'লেভেল ২ সেশন';

  @override
  String get navCatalog => 'ক্যাটালগ';

  @override
  String get navProviders => 'সেবাদাতা';

  @override
  String get navCustomers => 'গ্রাহক';

  @override
  String get navBookings => 'বুকিং';

  @override
  String get navComplaints => 'অভিযোগ';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get loginTitle => 'পাও অ্যাডমিনে সাইন ইন করুন';

  @override
  String get loginEmail => 'অফিসের ইমেইল';

  @override
  String get loginPassword => 'পাসওয়ার্ড';

  @override
  String get loginSubmit => 'সাইন ইন';

  @override
  String get loginEnrolBody =>
      'প্রথমবার সাইন ইন: এই কী-টি আপনার অথেনটিকেটর অ্যাপে যোগ করুন।';

  @override
  String get loginCodeBody => 'অথেনটিকেটর অ্যাপের ৬ সংখ্যার কোডটি দিন।';

  @override
  String get loginBack => 'অন্য অ্যাকাউন্ট ব্যবহার করুন';

  @override
  String get passwordTitle => 'নতুন পাসওয়ার্ড বেছে নিন';

  @override
  String get passwordBody =>
      'এগিয়ে যাওয়ার আগে আমন্ত্রণের অস্থায়ী পাসওয়ার্ডটি বদলে নিন।';

  @override
  String get passwordCurrent => 'বর্তমান পাসওয়ার্ড';

  @override
  String get passwordNew => 'নতুন পাসওয়ার্ড (অন্তত ১২ অক্ষর)';

  @override
  String get passwordRepeat => 'নতুন পাসওয়ার্ড আবার লিখুন';

  @override
  String get passwordTooShort => 'নতুন পাসওয়ার্ডে অন্তত ১২টি অক্ষর লাগবে।';

  @override
  String get passwordMismatch => 'দুটি নতুন পাসওয়ার্ড এক নয়।';

  @override
  String get reasonLabel => 'কারণ';

  @override
  String reasonTooShort(int count) {
    return 'অন্তত $countটি অক্ষর লিখুন।';
  }

  @override
  String get verifyQueueTitle => 'যাচাইয়ের সারি';

  @override
  String get verifyQueueEmpty => 'পর্যালোচনার অপেক্ষায় কোনো প্রোভাইডার নেই।';

  @override
  String get verifyFilterItem => 'অপেক্ষমাণ আইটেম';

  @override
  String get verifyFilterAll => 'সব আইটেম';

  @override
  String get verifyColProvider => 'প্রোভাইডার';

  @override
  String get verifyColServices => 'সেবা';

  @override
  String get verifyColPending => 'পর্যালোচনার অপেক্ষায়';

  @override
  String get verifyColWaiting => 'অপেক্ষার সময়';

  @override
  String verifyAgeHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ঘণ্টা';
  }

  @override
  String verifyAgeDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString দিন';
  }

  @override
  String get verifyItemNid => 'জাতীয় পরিচয়পত্র';

  @override
  String get verifyItemSelfie => 'লাইভ সেলফি';

  @override
  String get verifyItemPolice => 'পুলিশ ক্লিয়ারেন্স';

  @override
  String get verifyItemAddress => 'ঠিকানা';

  @override
  String get verifyItemEmergency => 'জরুরি যোগাযোগ';

  @override
  String get verifyItemSkill => 'দক্ষতার প্রমাণ';

  @override
  String get verifyItemServiceArea => 'সেবা এলাকা';

  @override
  String get verifyItemConduct => 'আচরণবিধি';

  @override
  String get verifyStatusMissing => 'জমা হয়নি';

  @override
  String get verifyStatusPending => 'অপেক্ষমাণ';

  @override
  String get verifyStatusApproved => 'অনুমোদিত';

  @override
  String get verifyStatusRejected => 'বাতিল';

  @override
  String get verifyStatusExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String get verifyRequired => 'আবশ্যক';

  @override
  String get verifyOptional => 'ঐচ্ছিক';

  @override
  String get verifyLevel0 => 'লেভেল ০ · নিবন্ধিত';

  @override
  String get verifyLevel1 => 'লেভেল ১ · যাচাইকৃত';

  @override
  String get verifyLevel2 => 'লেভেল ২ · PAO যাচাইকৃত প্রো';

  @override
  String get verifyFaceTitle => 'চেহারা মিলানো';

  @override
  String get verifyFaceNotRun => 'এখনো যাচাই হয়নি';

  @override
  String get verifyFaceMatch => 'চেহারা মিলেছে';

  @override
  String get verifyFaceNoMatch => 'চেহারা মেলেনি';

  @override
  String get verifyFaceManual => 'সেলফিটি এনআইডির ছবির সঙ্গে মিলিয়ে দেখুন';

  @override
  String get verifyGenderFemale => 'নারী';

  @override
  String get verifyGenderMale => 'পুরুষ';

  @override
  String get verifyGenderOther => 'অন্যান্য';

  @override
  String get verifyDocNidFront => 'এনআইডির সামনের দিক';

  @override
  String get verifyDocNidBack => 'এনআইডির পেছনের দিক';

  @override
  String get verifyFieldIssueDate => 'ইস্যুর তারিখ';

  @override
  String get verifyFieldRadius => 'কাজের পরিধি (মিটার)';

  @override
  String get verifyFieldServices => 'বাছাই করা সেবা';

  @override
  String get verifyFieldHomeLat => 'বাসার অক্ষাংশ';

  @override
  String get verifyFieldHomeLng => 'বাসার দ্রাঘিমাংশ';

  @override
  String get verifyFieldName => 'নাম';

  @override
  String get verifyFieldRelation => 'সম্পর্ক';

  @override
  String get verifyProfileTitle => 'এনআইডি ও প্রোফাইল';

  @override
  String get verifyNidNumber => 'এনআইডি নম্বর';

  @override
  String get verifyFullName => 'পুরো নাম';

  @override
  String get verifyDob => 'জন্মতারিখ';

  @override
  String get verifyGender => 'লিঙ্গ';

  @override
  String get verifyPhone => 'ফোন';

  @override
  String get verifyPresentAddress => 'বর্তমান ঠিকানা';

  @override
  String get verifyPermanentAddress => 'স্থায়ী ঠিকানা';

  @override
  String get verifyNotGiven => 'দেওয়া হয়নি';

  @override
  String get verifyReasonBlurry => 'ছবিটি ঝাপসা। ভালো আলোতে আবার তুলুন।';

  @override
  String get verifyReasonName => 'নামটি প্রোফাইলের সঙ্গে মেলে না।';

  @override
  String get verifyReasonExpired => 'কাগজটির মেয়াদ শেষ হয়ে গেছে।';

  @override
  String get verifyReasonFace => 'সেলফিটি এনআইডির ছবির সঙ্গে মেলে না।';

  @override
  String get verifyReasonCropped => 'কাগজটির কিছু অংশ কাটা পড়েছে।';

  @override
  String verifyRejectedBecause(String reason) {
    return 'বাতিলের কারণ: $reason';
  }

  @override
  String verifyExpires(String date) {
    return 'মেয়াদ শেষ $date';
  }

  @override
  String verifyDecidedAt(String date) {
    return 'সিদ্ধান্ত $date';
  }

  @override
  String get verifyOpenDocs => 'কাগজপত্র খুলুন';

  @override
  String get verifyDocsLocked => 'আপনি কাগজপত্র খুলতে পারবেন না';

  @override
  String get verifyApprove => 'অনুমোদন';

  @override
  String get verifyReject => 'বাতিল করুন';

  @override
  String verifyRejectTitle(String item) {
    return '$item বাতিল করুন';
  }

  @override
  String get verifyReviewTitle => 'যাচাই পর্যালোচনা';

  @override
  String get verifyBackToQueue => 'সারিতে ফিরে যান';

  @override
  String get verifyNext => 'পরের প্রোভাইডার';

  @override
  String get verifyShortcuts => 'কী: A অনুমোদন · R বাতিল · N পরের জন · ↑↓ সরান';

  @override
  String get verifyNoPending => 'সিদ্ধান্তের অপেক্ষায় কিছু নেই।';

  @override
  String verifyDecided(String level) {
    return 'সংরক্ষিত হয়েছে। প্রোভাইডার এখন $level-এ।';
  }

  @override
  String get verifyQueueDone => 'আর কোনো প্রোভাইডার অপেক্ষায় নেই।';

  @override
  String get verifyViewerBroken => 'কাগজটি দেখানো গেল না।';

  @override
  String get verifyViewerZoomIn => 'বড় করুন';

  @override
  String get verifyViewerZoomOut => 'ছোট করুন';

  @override
  String get verifyViewerRotateLeft => 'বাঁয়ে ঘোরান';

  @override
  String get verifyViewerRotateRight => 'ডানে ঘোরান';

  @override
  String get level2Title => 'লেভেল ২ সেশন';

  @override
  String get level2Schedule => 'সেশন নির্ধারণ';

  @override
  String get level2Empty => 'কোনো সেশন মেলেনি।';

  @override
  String get level2ColWhen => 'কখন';

  @override
  String get level2ColProvider => 'প্রোভাইডার';

  @override
  String get level2ColService => 'সেবা';

  @override
  String get level2ColStatus => 'অবস্থা';

  @override
  String get level2StatusScheduled => 'নির্ধারিত';

  @override
  String get level2StatusCompleted => 'সম্পন্ন';

  @override
  String get level2StatusCancelled => 'বাতিল';

  @override
  String get level2ResultPass => 'উত্তীর্ণ';

  @override
  String get level2ResultFail => 'অনুত্তীর্ণ';

  @override
  String get level2ResultRetest => 'আবার পরীক্ষা';

  @override
  String get level2FilterStatus => 'অবস্থা';

  @override
  String get level2AllStatuses => 'সব অবস্থা';

  @override
  String get level2FilterProvider => 'প্রোভাইডার';

  @override
  String get level2AnyProvider => 'যেকোনো';

  @override
  String get level2FindProvider => 'প্রোভাইডার খুঁজুন';

  @override
  String get level2FindHint => 'নাম বা ফোন লিখে Enter চাপুন';

  @override
  String get level2NoProviders => 'কোনো প্রোভাইডার মেলেনি।';

  @override
  String get level2ScheduleTitle => 'লেভেল ২ সেশন নির্ধারণ';

  @override
  String get level2ChangeProvider => 'বদলান';

  @override
  String get level2NoServices => 'এই প্রোভাইডার কোনো সেবা বাছাই করেননি।';

  @override
  String get level2Service => 'সেবা';

  @override
  String get level2Date => 'তারিখ';

  @override
  String get level2Time => 'সময় (ঢাকা)';

  @override
  String get level2Location => 'স্থান';

  @override
  String get level2LocationHint => 'PAO অফিস, গুলশান ১';

  @override
  String get level2ScheduleSubmit => 'নির্ধারণ করুন';

  @override
  String get level2ScheduleMissing =>
      'একজন প্রোভাইডার, একটি সেবা ও স্থান বেছে নিন।';

  @override
  String get level2PastTime => 'ভবিষ্যতের একটি সময় বেছে নিন।';

  @override
  String get level2Booked => 'সেশন নির্ধারিত হয়েছে। প্রোভাইডারকে জানানো হবে।';

  @override
  String get level2NotEligible =>
      'শুধু লেভেল ১ প্রোভাইডাররা লেভেল ২ সেশন নিতে পারেন।';

  @override
  String get level2CoolingOff =>
      'এই প্রোভাইডার সম্প্রতি অনুত্তীর্ণ হয়েছেন; আবার চেষ্টার আগে অপেক্ষা করতে হবে।';

  @override
  String get level2SessionTitle => 'লেভেল ২ সেশন';

  @override
  String get level2Checklist => 'চেকলিস্ট';

  @override
  String get level2ItemPassed => 'উত্তীর্ণ';

  @override
  String get level2ItemFailed => 'উত্তীর্ণ নয়';

  @override
  String get level2AddItem => 'চেকলিস্টে আইটেম যোগ করুন';

  @override
  String get level2Outcome => 'ফলাফল';

  @override
  String get level2Notes => 'মন্তব্য';

  @override
  String get level2Record => 'ফলাফল সংরক্ষণ';

  @override
  String get level2NeedChecklist => 'অন্তত একটি চেকলিস্ট আইটেম যোগ করুন।';

  @override
  String get level2NeedResult =>
      'উত্তীর্ণ, অনুত্তীর্ণ বা আবার পরীক্ষা বেছে নিন।';
}
