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
  String get peopleStatusPending => 'অপেক্ষমাণ';

  @override
  String get peopleStatusActive => 'সক্রিয়';

  @override
  String get peopleStatusSuspended => 'স্থগিত';

  @override
  String get peopleStatusBanned => 'নিষিদ্ধ';

  @override
  String get peopleFilterStatus => 'অবস্থা';

  @override
  String get peopleFilterAny => 'সব';

  @override
  String get peopleName => 'নাম';

  @override
  String get peoplePhone => 'ফোন';

  @override
  String get peopleRating => 'রেটিং';

  @override
  String get peopleNoRating => 'এখনো রেটিং নেই';

  @override
  String get peopleJoined => 'যোগদান';

  @override
  String get peopleSuspend => 'স্থগিত করুন';

  @override
  String get peopleBan => 'নিষিদ্ধ করুন';

  @override
  String get peopleReinstate => 'পুনর্বহাল করুন';

  @override
  String peopleSuspendTitle(String name) {
    return '$name-কে স্থগিত করবেন?';
  }

  @override
  String peopleBanTitle(String name) {
    return '$name-কে নিষিদ্ধ করবেন? এই ফোন নম্বর দিয়ে আর নিবন্ধন করা যাবে না।';
  }

  @override
  String peopleReinstateTitle(String name) {
    return '$name-কে পুনর্বহাল করবেন?';
  }

  @override
  String get peopleReasonResolved => 'পর্যালোচনার পর সমস্যার সমাধান হয়েছে';

  @override
  String get peopleReasonAppeal => 'আপিল গ্রহণ করা হয়েছে';

  @override
  String get peopleStatusChanged => 'অ্যাকাউন্টের অবস্থা হালনাগাদ হয়েছে।';

  @override
  String get peopleRecentBookings => 'সাম্প্রতিক বুকিং';

  @override
  String get peopleNoBookings => 'এখনো কোনো বুকিং নেই।';

  @override
  String get peopleHistory => 'অবস্থার ইতিহাস';

  @override
  String get peopleHistoryEmpty => 'এখনো অবস্থার কোনো পরিবর্তন হয়নি।';

  @override
  String peopleHistoryBy(String role) {
    return '$role করেছেন';
  }

  @override
  String get providersTitle => 'সেবাদাতা';

  @override
  String get providersSearch => 'নাম বা ফোন দিয়ে সেবাদাতা খুঁজুন';

  @override
  String get providersEmpty => 'এই ফিল্টারে কোনো সেবাদাতা নেই।';

  @override
  String get providersAll => 'সব সেবাদাতা';

  @override
  String get providersLevel => 'লেভেল';

  @override
  String get providersLevel0 => 'নিবন্ধিত';

  @override
  String get providersLevel1 => 'যাচাইকৃত';

  @override
  String get providersLevel2 => 'পাও ভেরিফায়েড প্রো';

  @override
  String get providersFlagged => 'পর্যালোচনার জন্য চিহ্নিত';

  @override
  String get providersOnline => 'অনলাইন';

  @override
  String get providersJobs => 'সম্পন্ন কাজ';

  @override
  String get providersProfile => 'প্রোফাইল';

  @override
  String get providersServices => 'সেবা';

  @override
  String get providersComplaints => 'অভিযোগ';

  @override
  String get providersCancellations => 'বাতিল (৩০ দিন)';

  @override
  String get providersGender => 'লিঙ্গ';

  @override
  String get providersGenderFemale => 'নারী';

  @override
  String get providersGenderMale => 'পুরুষ';

  @override
  String get providersGenderOther => 'অন্যান্য';

  @override
  String get providersExperience => 'অভিজ্ঞতা';

  @override
  String providersExperienceYears(String years) {
    return '$years বছর';
  }

  @override
  String get providersVerification => 'যাচাই';

  @override
  String get providersNoItems => 'এখনো কিছু জমা দেওয়া হয়নি।';

  @override
  String get providersOptional => 'ঐচ্ছিক';

  @override
  String providersItemExpires(String date) {
    return 'মেয়াদ শেষ $date';
  }

  @override
  String get providersItemNid => 'জাতীয় পরিচয়পত্র';

  @override
  String get providersItemSelfie => 'সেলফি';

  @override
  String get providersItemPoliceClearance => 'পুলিশ ক্লিয়ারেন্স';

  @override
  String get providersItemAddress => 'ঠিকানা';

  @override
  String get providersItemEmergencyContact => 'জরুরি যোগাযোগ';

  @override
  String get providersItemSkillProof => 'দক্ষতার প্রমাণ';

  @override
  String get providersItemServiceArea => 'সেবা এলাকা';

  @override
  String get providersItemCodeOfConduct => 'আচরণবিধি';

  @override
  String get providersItemMissing => 'জমা হয়নি';

  @override
  String get providersItemPending => 'পর্যালোচনাধীন';

  @override
  String get providersItemApproved => 'অনুমোদিত';

  @override
  String get providersItemRejected => 'প্রত্যাখ্যাত';

  @override
  String get providersItemExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String providersBanTitle(String name) {
    return '$name-কে নিষিদ্ধ করবেন? তাঁর এনআইডি, ফোন ও চেহারা দিয়ে আর নিবন্ধন করা যাবে না।';
  }

  @override
  String get providersReasonNoShow => 'বারবার উপস্থিত না হওয়া';

  @override
  String get providersReasonComplaint => 'যাচাইকৃত অভিযোগ';

  @override
  String get providersReasonRating => 'রেটিং ন্যূনতম সীমার নিচে';

  @override
  String get providersReasonFraud => 'জাল কাগজপত্র';

  @override
  String get customersTitle => 'গ্রাহক';

  @override
  String get customersSearch => 'নাম বা ফোন দিয়ে গ্রাহক খুঁজুন';

  @override
  String get customersEmpty => 'এই ফিল্টারে কোনো গ্রাহক নেই।';

  @override
  String get customersAll => 'সব গ্রাহক';

  @override
  String get customersBookings => 'মোট বুকিং';

  @override
  String get customersProfile => 'প্রোফাইল';

  @override
  String get customersComplaints => 'অভিযোগ ও রিপোর্ট';

  @override
  String get customersNoComplaints => 'এখনো কোনো অভিযোগ নেই।';

  @override
  String get customersReasonAbuse => 'অশোভন আচরণ';

  @override
  String get customersReasonFake => 'বারবার ভুয়া বুকিং';

  @override
  String get customersReasonPayment => 'টাকা দিতে অস্বীকার';

  @override
  String get bookingsTitle => 'বুকিং';

  @override
  String bookingsAutoRefresh(String seconds) {
    return 'প্রতি $seconds সেকেন্ডে হালনাগাদ হয়';
  }

  @override
  String get bookingsAreaHint => 'এলাকা দিয়ে খুঁজুন, যেমন বনানী';

  @override
  String get bookingsAnyDate => 'যেকোনো তারিখ';

  @override
  String get bookingsClearDates => 'তারিখ মুছুন';

  @override
  String get bookingsEmpty => 'এই ফিল্টারে কোনো বুকিং নেই।';

  @override
  String get bookingsAll => 'সব বুকিং';

  @override
  String get bookingsNumber => 'বুকিং';

  @override
  String get bookingsService => 'সেবা';

  @override
  String get bookingsCreated => 'তৈরি';

  @override
  String get bookingsTotal => 'মোট';

  @override
  String get bookingsWhen => 'নির্ধারিত সময়';

  @override
  String get bookingsAsap => 'যত দ্রুত সম্ভব';

  @override
  String get bookingsEnds => 'ভাড়া শেষ';

  @override
  String get bookingsStarted => 'কাজ শুরু';

  @override
  String get bookingsFinished => 'কাজ শেষ';

  @override
  String get bookingsPayment => 'পেমেন্ট';

  @override
  String get bookingsCash => 'নগদ';

  @override
  String get bookingsCashReceived => 'নগদ পাওয়া গেছে';

  @override
  String get bookingsAddress => 'ঠিকানা';

  @override
  String get bookingsNote => 'গ্রাহকের নোট';

  @override
  String bookingsCancelledBy(String actor) {
    return '$actor বাতিল করেছেন';
  }

  @override
  String get bookingsParties => 'গ্রাহক ও সেবাদাতা';

  @override
  String get bookingsCustomer => 'গ্রাহক';

  @override
  String get bookingsProvider => 'সেবাদাতা';

  @override
  String get bookingsNotAssigned => 'এখনো নির্ধারিত হয়নি';

  @override
  String get bookingsActorSystem => 'সিস্টেম';

  @override
  String get bookingsActorAdmin => 'অ্যাডমিন';

  @override
  String get bookingsItems => 'আইটেম';

  @override
  String bookingsQty(String quantity, String price) {
    return '$quantity × $price';
  }

  @override
  String get bookingsExtra => 'অতিরিক্ত';

  @override
  String get bookingsExtras => 'প্রস্তাবিত অতিরিক্ত কাজ';

  @override
  String get bookingsExtrasPending => 'গ্রাহকের সম্মতির অপেক্ষায়';

  @override
  String get bookingsExtrasApproved => 'গ্রাহক অনুমোদন করেছেন';

  @override
  String get bookingsExtrasDeclined => 'গ্রাহক প্রত্যাখ্যান করেছেন';

  @override
  String bookingsExtrasAdded(String added, String total) {
    return '$added যোগ হবে; নতুন মোট $total';
  }

  @override
  String get bookingsTimeline => 'সময়রেখা';

  @override
  String get bookingsStatusRequested => 'অনুরোধ করা হয়েছে';

  @override
  String get bookingsStatusAccepted => 'গৃহীত';

  @override
  String get bookingsStatusOnTheWay => 'পথে আছেন';

  @override
  String get bookingsStatusArrived => 'পৌঁছেছেন';

  @override
  String get bookingsStatusInProgress => 'কাজ চলছে';

  @override
  String get bookingsStatusCompleted => 'সম্পন্ন';

  @override
  String get bookingsStatusRejected => 'প্রত্যাখ্যাত';

  @override
  String get bookingsStatusTimedOut => 'সময় পেরিয়ে গেছে';

  @override
  String get bookingsStatusCancelled => 'বাতিল';

  @override
  String get complaintsTitle => 'অভিযোগ';

  @override
  String get complaintsMine => 'আমার দায়িত্বে';

  @override
  String get complaintsEmpty => 'এই ফিল্টারে কোনো অভিযোগ নেই।';

  @override
  String get complaintsAll => 'সব অভিযোগ';

  @override
  String get complaintsTicket => 'টিকিট';

  @override
  String get complaintsReason => 'কারণ';

  @override
  String get complaintsReporter => 'অভিযোগকারী';

  @override
  String get complaintsOpened => 'খোলা হয়েছে';

  @override
  String get complaintsStatusOpen => 'খোলা';

  @override
  String get complaintsStatusAssigned => 'দায়িত্ব দেওয়া হয়েছে';

  @override
  String get complaintsStatusResolved => 'সমাধান হয়েছে';

  @override
  String get complaintsReasonNoShow => 'উপস্থিত হননি';

  @override
  String get complaintsReasonLate => 'দেরি';

  @override
  String get complaintsReasonPoorQuality => 'কাজের মান খারাপ';

  @override
  String get complaintsReasonOvercharge => 'বেশি টাকা নেওয়া';

  @override
  String get complaintsReasonDamage => 'ক্ষতি';

  @override
  String get complaintsReasonBehaviour => 'আচরণ';

  @override
  String get complaintsReasonSafety => 'নিরাপত্তা';

  @override
  String get complaintsReasonCustomerUnavailable => 'গ্রাহক অনুপস্থিত';

  @override
  String get complaintsReasonPayment => 'পেমেন্ট';

  @override
  String get complaintsReasonOther => 'অন্যান্য';

  @override
  String get complaintsByCustomer => 'গ্রাহক';

  @override
  String get complaintsByProvider => 'সেবাদাতা';

  @override
  String get complaintsAssignee => 'দায়িত্বপ্রাপ্ত';

  @override
  String get complaintsUnassigned => 'এখনো কেউ নন';

  @override
  String get complaintsYou => 'আপনি';

  @override
  String complaintsAgent(String id) {
    return 'এজেন্ট $id';
  }

  @override
  String get complaintsDescription => 'কী ঘটেছে';

  @override
  String get complaintsOpenBooking => 'বুকিংটি দেখুন';

  @override
  String get complaintsReporterProfile => 'অভিযোগকারীর প্রোফাইল';

  @override
  String get complaintsAgainstProfile => 'অপর পক্ষের প্রোফাইল';

  @override
  String get complaintsEvidence => 'প্রমাণের ছবি';

  @override
  String get complaintsNoEvidence => 'কোনো ছবি যুক্ত নেই।';

  @override
  String complaintsPhoto(String number) {
    return 'ছবি $number';
  }

  @override
  String get complaintsPhotoPending =>
      'অভিযোগের ছবি এখানে খোলার সুবিধা এখনো চালু হয়নি।';

  @override
  String get complaintsComments => 'অভ্যন্তরীণ মন্তব্য';

  @override
  String get complaintsNoComments => 'এখনো কোনো মন্তব্য নেই।';

  @override
  String get complaintsCommentHint => 'দলের জন্য একটি নোট লিখুন';

  @override
  String get complaintsCommentSend => 'মন্তব্য যোগ করুন';

  @override
  String get complaintsCommented => 'মন্তব্য যোগ হয়েছে।';

  @override
  String get complaintsActions => 'করণীয়';

  @override
  String get complaintsAssignMe => 'নিজের দায়িত্বে নিন';

  @override
  String get complaintsAssignOther => 'অন্য এজেন্টকে দিন';

  @override
  String get complaintsPickAgent => 'একজন সাপোর্ট এজেন্ট বেছে নিন';

  @override
  String get complaintsNoAgents => 'কোনো সক্রিয় সাপোর্ট এজেন্ট নেই।';

  @override
  String get complaintsAssigned => 'অভিযোগের দায়িত্ব দেওয়া হয়েছে।';

  @override
  String get complaintsResolve => 'সমাধান করুন';

  @override
  String complaintsResolveTitle(String ticket) {
    return '$ticket সমাধান করুন';
  }

  @override
  String get complaintsResolution => 'সমাধানের নোট';

  @override
  String get complaintsVerified => 'যাচাইকৃত অভিযোগ';

  @override
  String get complaintsVerifiedHelp =>
      'যাচাইকৃত অভিযোগ সেবাদাতার মান পর্যালোচনায় গণ্য হয়।';

  @override
  String get complaintsNotVerified => 'যাচাইকৃত নয়';

  @override
  String get complaintsResolved => 'অভিযোগের সমাধান হয়েছে।';

  @override
  String get complaintsResolutionTitle => 'সমাধান';

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

  @override
  String get formRequired => 'এটি পূরণ করুন।';

  @override
  String formTooLong(String max) {
    return '$max অক্ষরের মধ্যে রাখুন।';
  }

  @override
  String get formWhole => 'একটি পূর্ণ সংখ্যা লিখুন।';

  @override
  String get formNumber => 'একটি সংখ্যা লিখুন।';

  @override
  String formAtLeast(String min) {
    return '$min বা তার বেশি লিখুন।';
  }

  @override
  String formRange(String min, String max) {
    return '$min থেকে $max এর মধ্যে একটি সংখ্যা লিখুন।';
  }

  @override
  String get formMoney => 'টাকার অঙ্ক লিখুন, যেমন ৫০০ বা ৪৯৯.৫০।';

  @override
  String get formEmail => 'সঠিক ইমেইল ঠিকানা লিখুন।';

  @override
  String get formSaved => 'সংরক্ষিত হয়েছে।';

  @override
  String get dashTitle => 'ড্যাশবোর্ড';

  @override
  String dashUpdated(String time) {
    return 'হালনাগাদ: $time';
  }

  @override
  String get dashRefresh => 'রিফ্রেশ করুন';

  @override
  String get dashPendingVerifications => 'যাচাইয়ের অপেক্ষায়';

  @override
  String get dashOpenComplaints => 'খোলা অভিযোগ';

  @override
  String get dashCompletionRate => 'সম্পন্ন হওয়ার হার';

  @override
  String get dashBookings => 'এই সময়ের বুকিং';

  @override
  String get dashActiveProviders => 'সক্রিয় সেবাদাতা';

  @override
  String get dashBookingsPerDay => 'দৈনিক বুকিং';

  @override
  String get dashLegendTotal => 'সব বুকিং';

  @override
  String get dashLegendCompleted => 'সম্পন্ন';

  @override
  String dashDayTip(String day, String total, String completed) {
    return '$day: $totalটি বুকিং, $completedটি সম্পন্ন';
  }

  @override
  String get dashNoBookings => 'এই সময়ে এখনো কোনো বুকিং নেই।';

  @override
  String get dashProvidersByStatus => 'অবস্থা অনুযায়ী সেবাদাতা';

  @override
  String get dashProvidersByLevel => 'লেভেল অনুযায়ী সেবাদাতা';

  @override
  String get dashNoProviders => 'এখনো কোনো সেবাদাতা নেই।';

  @override
  String get dashStatusPending => 'অপেক্ষমাণ';

  @override
  String get dashStatusActive => 'সক্রিয়';

  @override
  String get dashStatusSuspended => 'স্থগিত';

  @override
  String get dashStatusBanned => 'নিষিদ্ধ';

  @override
  String get dashLevel0 => 'লেভেল ০ · নিবন্ধিত';

  @override
  String get dashLevel1 => 'লেভেল ১ · যাচাইকৃত';

  @override
  String get dashLevel2 => 'লেভেল ২ · পাও ভেরিফাইড প্রো';

  @override
  String get catalogTitle => 'ক্যাটালগ';

  @override
  String catalogVersion(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get catalogEmptyTitle => 'এখনো কোনো ক্যাটাগরি নেই';

  @override
  String get catalogEmptyBody =>
      'একটি ক্যাটাগরি যোগ করুন, তারপর এতে গ্রাহকেরা যে সেবাগুলো বুক করতে পারবেন সেগুলো যোগ করুন।';

  @override
  String get catalogNewCategory => 'নতুন ক্যাটাগরি';

  @override
  String get catalogEditCategory => 'ক্যাটাগরি সম্পাদনা';

  @override
  String catalogCategoryLine(String other, String order, String count) {
    return '$other · ক্রম $order · $countটি সেবা';
  }

  @override
  String get catalogNewService => 'নতুন সেবা';

  @override
  String get catalogServiceTitle => 'সেবা';

  @override
  String get catalogBack => 'ক্যাটালগে ফিরুন';

  @override
  String get catalogPublished => 'প্রকাশিত';

  @override
  String get catalogHidden => 'লুকানো';

  @override
  String get catalogPublishedSwitch => 'প্রকাশিত';

  @override
  String get catalogPublishedHint => 'গ্রাহকেরা অ্যাপে এটি দেখতে পাবেন।';

  @override
  String get catalogName => 'নাম';

  @override
  String get catalogDescription => 'বিবরণ';

  @override
  String catalogInEnglish(String label) {
    return '$label (ইংরেজি)';
  }

  @override
  String catalogInBangla(String label) {
    return '$label (বাংলা)';
  }

  @override
  String get catalogIconKey => 'আইকন কী';

  @override
  String get catalogPickIcon => 'পরিচিত আইকন বেছে নিন';

  @override
  String get catalogSortOrder => 'সাজানোর ক্রম';

  @override
  String get catalogAddRow => 'যোগ করুন';

  @override
  String get catalogRemoveRow => 'সরান';

  @override
  String get catalogServiceDetails => 'সেবার বিবরণ';

  @override
  String get catalogCategory => 'ক্যাটাগরি';

  @override
  String get catalogModel => 'সেবার ধরন';

  @override
  String get catalogLevel => 'প্রয়োজনীয় লেভেল';

  @override
  String get catalogRadius => 'খোঁজার পরিধি (মিটার)';

  @override
  String get catalogRadiusHint => '৫০০ থেকে ৫০০০০';

  @override
  String get catalogWomenOnly => 'শুধু নারী সেবাদাতা';

  @override
  String get catalogWomenOnlyHint => 'অনুরোধ শুধু নারী সেবাদাতাদের কাছে যাবে।';

  @override
  String get catalogRequiresLevel2 => 'লেভেল ২ প্রয়োজন';

  @override
  String get catalogRequiresLevel2Hint =>
      'সেবাদাতাদের আগে সরাসরি দক্ষতা যাচাইয়ে উত্তীর্ণ হতে হবে।';

  @override
  String get catalogChecklistItem => 'চেকলিস্টের বিষয়';

  @override
  String get catalogModelOnDemand => 'চাহিদামতো ভিজিট';

  @override
  String get catalogModelDuration => 'সময়ভিত্তিক নিয়োগ';

  @override
  String get catalogModelListing => 'তালিকা';

  @override
  String get catalogModelPartner => 'পার্টনার রেফারেল';

  @override
  String get catalogUnitJob => 'প্রতি কাজ';

  @override
  String get catalogUnitUnit => 'প্রতি ইউনিট';

  @override
  String get catalogUnitHour => 'প্রতি ঘণ্টা';

  @override
  String get catalogUnitDay => 'প্রতি দিন';

  @override
  String get catalogSubServices => 'উপ-সেবা';

  @override
  String get catalogNoSubServices =>
      'এখনো কোনো উপ-সেবা নেই। গ্রাহকেরা যেন এই সেবা বুক করতে পারেন, সেজন্য একটি যোগ করুন।';

  @override
  String get catalogNewSubService => 'নতুন উপ-সেবা';

  @override
  String get catalogEditSub => 'উপ-সেবা সম্পাদনা';

  @override
  String catalogMaxLine(String count) {
    return 'সর্বোচ্চ $count';
  }

  @override
  String get catalogInclusion => 'অন্তর্ভুক্ত';

  @override
  String get catalogExclusion => 'অন্তর্ভুক্ত নয়';

  @override
  String get catalogUnit => 'মূল্য নির্ধারণ';

  @override
  String get catalogMaxQuantity => 'প্রতি বুকিংয়ে সর্বোচ্চ';

  @override
  String get catalogMaxQuantityHint => 'সীমা না থাকলে খালি রাখুন';

  @override
  String get catalogFirstPrice => 'মূল্য';

  @override
  String get catalogPrices => 'মূল্য';

  @override
  String catalogPricesOf(String name) {
    return '$name এর মূল্য';
  }

  @override
  String get catalogPriceNote =>
      'নতুন মূল্য এখন থেকে করা বুকিংয়ে প্রযোজ্য হবে। আগের বুকিং তাদের সময়ের মূল্যেই থাকবে।';

  @override
  String catalogNewPrice(String unit) {
    return 'নতুন মূল্য ($unit)';
  }

  @override
  String get catalogSetPrice => 'নতুন মূল্য নির্ধারণ করুন';

  @override
  String get catalogPriceChanged => 'মূল্য হালনাগাদ হয়েছে।';

  @override
  String get catalogPriceHistory => 'মূল্যের ইতিহাস';

  @override
  String get catalogNoPrices => 'এখনো কোনো মূল্য রেকর্ড হয়নি।';

  @override
  String catalogPriceSince(String when, String admin) {
    return '$when থেকে · $admin দ্বারা';
  }

  @override
  String get catalogCurrentPrice => 'বর্তমান';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsTabSettings => 'প্ল্যাটফর্ম সেটিংস';

  @override
  String get settingsTabAdmins => 'অ্যাডমিন ব্যবহারকারী';

  @override
  String get settingsTabRoles => 'ভূমিকা';

  @override
  String get settingsTabAudit => 'অডিট লগ';

  @override
  String get settingsEmpty => 'এখনো কোনো সেটিং নেই';

  @override
  String get settingsSearch => 'সেটিং খুঁজুন';

  @override
  String settingsUpdatedAt(String when) {
    return 'পরিবর্তিত: $when';
  }

  @override
  String get settingsEdit => 'সেটিং পরিবর্তন করুন';

  @override
  String get settingsValue => 'মান';

  @override
  String get settingsOn => 'চালু';

  @override
  String get settingsOff => 'বন্ধ';

  @override
  String get settingsShape => 'মানচিত্রের আকৃতি';

  @override
  String get settingsBadShape => '\"type\" সহ একটি GeoJSON অবজেক্ট দিন।';

  @override
  String get settingsApplyNow =>
      'পরিবর্তনটি সঙ্গে সঙ্গে কার্যকর হবে এবং অডিট লগে রেকর্ড থাকবে।';

  @override
  String get settingsRoleCustomer => 'গ্রাহক';

  @override
  String get settingsRoleProvider => 'সেবাদাতা';

  @override
  String get settingsRoleVerifier => 'যাচাইকারী';

  @override
  String get settingsRoleCatalogManager => 'ক্যাটালগ ব্যবস্থাপক';

  @override
  String get settingsRoleSupportAgent => 'সাপোর্ট এজেন্ট';

  @override
  String get settingsRoleSuperAdmin => 'সুপার অ্যাডমিন';

  @override
  String get adminsInvite => 'অ্যাডমিন আমন্ত্রণ';

  @override
  String get adminsSendInvite => 'আমন্ত্রণ পাঠান';

  @override
  String get adminsEmpty => 'এখনো কোনো অ্যাডমিন নেই';

  @override
  String get adminsEmail => 'অফিসের ইমেইল';

  @override
  String get adminsName => 'পুরো নাম';

  @override
  String get adminsNameShort => 'অন্তত ২টি অক্ষর লিখুন।';

  @override
  String get adminsRoles => 'ভূমিকা';

  @override
  String get adminsPickRole => 'অন্তত একটি ভূমিকা বেছে নিন।';

  @override
  String get adminsInvitedTitle => 'আমন্ত্রণ তৈরি হয়েছে';

  @override
  String adminsInvitedBody(String name) {
    return 'এই অস্থায়ী পাসওয়ার্ডটি গোপনে $name কে দিন। এটি শুধু একবার দেখানো হবে; প্রথমবার সাইন ইন করার সময় তিনি এটি বদলাবেন এবং ২এফএ চালু করবেন।';
  }

  @override
  String get adminsCopy => 'পাসওয়ার্ড কপি করুন';

  @override
  String get adminsCopied => 'কপি হয়েছে।';

  @override
  String get adminsDone => 'সম্পন্ন';

  @override
  String get adminsNeverSignedIn => 'এখনো সাইন ইন করেননি';

  @override
  String adminsLastSignIn(String when) {
    return 'সর্বশেষ সাইন ইন: $when';
  }

  @override
  String get adminsActive => 'সক্রিয়';

  @override
  String get adminsInactive => 'নিষ্ক্রিয়';

  @override
  String get adminsTotpOn => '২এফএ চালু';

  @override
  String get adminsTotpOff => '২এফএ বাকি';

  @override
  String get adminsEdit => 'ভূমিকা বা অ্যাক্সেস পরিবর্তন';

  @override
  String get adminsActiveSwitch => 'সাইন ইন করতে পারবেন';

  @override
  String get adminsActiveHint =>
      'এটি বন্ধ করলে তাঁর সব সেশন সঙ্গে সঙ্গে শেষ হবে।';

  @override
  String adminsDeactivateTitle(String name) {
    return '$name কে নিষ্ক্রিয় করবেন?';
  }

  @override
  String get adminsDeactivateBody =>
      'তিনি এখনই সব জায়গা থেকে সাইন আউট হবেন এবং আবার সক্রিয় না করা পর্যন্ত সাইন ইন করতে পারবেন না।';

  @override
  String get adminsDeactivate => 'নিষ্ক্রিয় করুন';

  @override
  String get rolesEmpty => 'কোনো ভূমিকা পাওয়া যায়নি';

  @override
  String get rolesApplyNow =>
      'ভূমিকার পরিবর্তন সঙ্গে সঙ্গে এই ভূমিকার সবার ওপর প্রযোজ্য হবে।';

  @override
  String rolesCounts(String permissions, String screens) {
    return '$permissionsটি অনুমতি · $screensটি স্ক্রিন';
  }

  @override
  String get rolesEdit => 'ভূমিকা সম্পাদনা';

  @override
  String get rolesPermissions => 'অনুমতি';

  @override
  String get rolesScreens => 'স্ক্রিন';

  @override
  String rolesConfirmTitle(String role) {
    return '$role ভূমিকায় পরিবর্তন প্রয়োগ করবেন?';
  }

  @override
  String get rolesApply => 'এখনই প্রয়োগ করুন';

  @override
  String get rolesSaved => 'ভূমিকা হালনাগাদ হয়েছে।';

  @override
  String get auditWhen => 'কখন';

  @override
  String get auditActor => 'কে';

  @override
  String get auditRole => 'ভূমিকা';

  @override
  String get auditAction => 'কাজ';

  @override
  String get auditSubject => 'বিষয়';

  @override
  String get auditReason => 'কারণ';

  @override
  String get auditBefore => 'আগে';

  @override
  String get auditAfter => 'পরে';

  @override
  String get auditSystem => 'সিস্টেম';

  @override
  String get auditEmpty => 'মেলে এমন কোনো অডিট এন্ট্রি নেই';

  @override
  String get auditActorId => 'কর্তার আইডি';

  @override
  String get auditActorInvalid => 'পুরো অ্যাকাউন্ট আইডি দিন।';

  @override
  String get auditActionHint => 'কাজ, যেমন catalog.price_changed';

  @override
  String get auditSubjectId => 'বিষয়ের আইডি';

  @override
  String get auditAnyDate => 'যেকোনো তারিখ';

  @override
  String get auditApply => 'প্রয়োগ করুন';

  @override
  String get auditClear => 'মুছুন';

  @override
  String get navPayments => 'পেমেন্ট';

  @override
  String get payTitle => 'মার্চেন্টের পেমেন্ট';

  @override
  String get payEmpty => 'মিলে যাওয়া কোনো পেমেন্ট নেই';

  @override
  String get payMerchant => 'মার্চেন্ট';

  @override
  String get payAmount => 'পরিমাণ';

  @override
  String get payMethod => 'মাধ্যম';

  @override
  String get payReference => 'রেফারেন্স';

  @override
  String get paySubmitted => 'জমা';

  @override
  String get payReviewed => 'পর্যালোচনা';

  @override
  String get payReason => 'কারণ';

  @override
  String get payStatusPending => 'অপেক্ষমাণ';

  @override
  String get payStatusConfirmed => 'নিশ্চিত';

  @override
  String get payStatusRejected => 'বাতিল';

  @override
  String get payCashToAgent => 'এজেন্টকে নগদ';

  @override
  String get payBkash => 'বিকাশ';

  @override
  String get payNagad => 'নগদ';

  @override
  String get payBank => 'ব্যাংক ট্রান্সফার';

  @override
  String get payConfirm => 'পেমেন্ট নিশ্চিত করুন';

  @override
  String get payReject => 'পেমেন্ট বাতিল করুন';

  @override
  String get payRejectTitle => 'কেন এই পেমেন্ট বাতিল করছেন?';

  @override
  String get payConfirmed => 'পেমেন্ট নিশ্চিত হয়েছে; হিসাবে জমা হয়েছে।';

  @override
  String get payRejected =>
      'পেমেন্ট বাতিল হয়েছে; মার্চেন্টকে কারণ জানানো হয়েছে।';

  @override
  String get payViewLedger => 'হিসাব দেখুন';

  @override
  String get ledgerTitle => 'মার্চেন্টের হিসাব';

  @override
  String get ledgerBack => 'পেমেন্ট';

  @override
  String get ledgerDue => 'বকেয়া';

  @override
  String get ledgerLimit => 'ব্লক সীমা';

  @override
  String get ledgerPending => 'অপেক্ষমাণ পেমেন্ট';

  @override
  String get ledgerRate => 'কমিশনের হার';

  @override
  String get ledgerBlocked => 'কাজ নেওয়া বন্ধ';

  @override
  String get ledgerClear => 'কাজ নিতে পারেন';

  @override
  String get ledgerEmpty => 'এখনো কোনো হিসাব নেই';

  @override
  String get ledgerKind => 'এন্ট্রি';

  @override
  String ledgerCommission(String number) {
    return 'কমিশন · $number';
  }

  @override
  String get ledgerPayment => 'পেমেন্ট';

  @override
  String get ledgerJobTotal => 'কাজের মোট';

  @override
  String get ledgerDate => 'তারিখ';

  @override
  String get settingsRateRange =>
      '০ থেকে ১০০০০ বেসিস পয়েন্ট লিখুন (১০০০ = ১০%)।';

  @override
  String get settingsRateHint =>
      'বেসিস পয়েন্ট: ১০০০ = চূড়ান্ত কাজের দামের ১০%।';

  @override
  String settingsRateValue(String percent, String bp) {
    return '$percent% ($bp বিপি)';
  }

  @override
  String get settingsAmountRange =>
      'পয়সায় ০ বা তার বেশি পূর্ণ সংখ্যা লিখুন (৫০০০০ = ৳৫০০)।';

  @override
  String get settingsAmountHint =>
      'পয়সা: ৫০০০০ = ৳৫০০। এর বেশি বকেয়ায় মার্চেন্ট কাজ নিতে পারবেন না।';
}
