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
}
