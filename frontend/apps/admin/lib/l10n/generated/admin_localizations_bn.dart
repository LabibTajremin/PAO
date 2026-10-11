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
}
