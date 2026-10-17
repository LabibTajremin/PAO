// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'pao_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class PaoL10nBn extends PaoL10n {
  PaoL10nBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'পাও';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get actionRetry => 'আবার চেষ্টা করুন';

  @override
  String get actionContinue => 'এগিয়ে যান';

  @override
  String get actionCancel => 'বাতিল';

  @override
  String get actionSave => 'সংরক্ষণ করুন';

  @override
  String get actionBack => 'পেছনে';

  @override
  String get actionClose => 'বন্ধ করুন';

  @override
  String get actionSeeAll => 'সব দেখুন';

  @override
  String get actionSignOut => 'লগ আউট';

  @override
  String get offlineBanner =>
      'আপনি অফলাইনে আছেন। নেটওয়ার্ক ফিরলে আবার যুক্ত হব।';

  @override
  String get loading => 'লোড হচ্ছে';

  @override
  String get emptyTitle => 'এখানে এখনও কিছু নেই';

  @override
  String get errorTitle => 'কিছু একটা ভুল হয়েছে';

  @override
  String get accessDenied => 'এই স্ক্রিনে আপনার প্রবেশাধিকার নেই।';

  @override
  String get sessionExpiredTitle => 'আবার স্বাগতম';

  @override
  String get sessionExpiredBody =>
      'আপনার নিরাপত্তার জন্য আমরা আপনাকে সাইন আউট করেছি। চালিয়ে যেতে আবার সাইন ইন করুন।';

  @override
  String get navHome => 'হোম';

  @override
  String get navBookings => 'বুকিং';

  @override
  String get navJobs => 'কাজ';

  @override
  String get navEarnings => 'আয়';

  @override
  String get navNotifications => 'নোটিফিকেশন';

  @override
  String get navAccount => 'অ্যাকাউন্ট';

  @override
  String ratingLabel(String rating) {
    return '৫-এর মধ্যে $rating তারা';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি আইটেম',
      zero: 'কোনো আইটেম নেই',
    );
    return '$_temp0';
  }

  @override
  String minutesAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count মিনিট দূরে',
    );
    return '$_temp0';
  }

  @override
  String get failureNetwork => 'সংযোগ নেই। ইন্টারনেট দেখে আবার চেষ্টা করুন।';

  @override
  String get failureTimeout => 'নেটওয়ার্ক ধীর। আবার চেষ্টা করুন।';

  @override
  String get failureSessionExpired =>
      'আপনার সেশন শেষ হয়েছে। আবার সাইন ইন করুন।';

  @override
  String get failureUnexpected => 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get errorValidationFailed => 'চিহ্নিত ঘরগুলো দেখে নিন।';

  @override
  String get errorUnauthenticated => 'আবার সাইন ইন করুন।';

  @override
  String get errorTokenExpired => 'আপনার সেশন শেষ হয়েছে। আবার সাইন ইন করুন।';

  @override
  String get errorForbidden => 'আপনার এটি করার অনুমতি নেই।';

  @override
  String get errorNotFound => 'এটি খুঁজে পাওয়া যায়নি।';

  @override
  String get errorConflict =>
      'এটি আগেই বদলানো হয়েছে। রিফ্রেশ করে আবার চেষ্টা করুন।';

  @override
  String get errorRateLimited => 'অনেকবার চেষ্টা হয়েছে। একটু অপেক্ষা করুন।';

  @override
  String get errorInternal => 'আমাদের সেবায় সমস্যা হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get errorNotImplemented => 'এটি এখনও চালু হয়নি।';

  @override
  String get errorOtpInvalid => 'কোডটি সঠিক নয়।';

  @override
  String get errorOtpExpired => 'কোডটির মেয়াদ শেষ। নতুন কোড নিন।';

  @override
  String get errorOtpLocked => 'অনেকবার ভুল কোড। পরে আবার চেষ্টা করুন।';

  @override
  String get errorAccountBanned => 'এই অ্যাকাউন্টটি বন্ধ করা হয়েছে।';

  @override
  String get errorAccountSuspended =>
      'এই অ্যাকাউন্ট স্থগিত। সাপোর্টে যোগাযোগ করুন।';

  @override
  String get errorInvalidCredentials => 'ইমেইল বা পাসওয়ার্ড ভুল।';

  @override
  String get errorAccountLocked =>
      'অনেকবার চেষ্টা হয়েছে। অ্যাকাউন্ট কিছু সময়ের জন্য লক।';

  @override
  String get errorTotpInvalid => 'অথেনটিকেটর কোডটি সঠিক নয়।';

  @override
  String get errorMfaChallengeExpired =>
      'সাইন ইনে অনেক সময় লেগেছে। আবার শুরু করুন।';

  @override
  String get errorRefreshTokenInvalid =>
      'আপনার সেশন শেষ হয়েছে। আবার সাইন ইন করুন।';

  @override
  String get errorIdempotencyKeyRequired =>
      'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get errorIdempotencyKeyReused => 'এই অনুরোধ আগেই পাঠানো হয়েছে।';

  @override
  String get errorAddressLimitReached =>
      'সর্বোচ্চ সংখ্যক ঠিকানা সংরক্ষণ করা হয়েছে।';

  @override
  String get errorOutsideServiceArea => 'এই এলাকায় এখনও পাও চালু হয়নি।';

  @override
  String get errorServiceUnavailable => 'এই সেবা এখন পাওয়া যাচ্ছে না।';

  @override
  String get errorProviderUnavailable => 'এই সেবাদাতা এখন ব্যস্ত বা অনুপলব্ধ।';

  @override
  String get errorDuplicateBookingRequest =>
      'এই সেবাদাতার কাছে আপনার একটি অনুরোধ আগেই আছে।';

  @override
  String get errorBookingInvalidTransition =>
      'এই বুকিং এখন এভাবে বদলানো যাবে না।';

  @override
  String get errorBookingAlreadyResponded =>
      'এই অনুরোধের উত্তর আগেই দেওয়া হয়েছে।';

  @override
  String get errorActiveJobExists => 'আগে চলমান কাজটি শেষ করুন।';

  @override
  String get errorStartCodeInvalid => 'শুরু করার কোডটি সঠিক নয়।';

  @override
  String get errorStartCodeLocked =>
      'অনেকবার ভুল কোড। কয়েক মিনিট পরে চেষ্টা করুন।';

  @override
  String get errorCancellationNotAllowed => 'এই বুকিং আর বাতিল করা যাবে না।';

  @override
  String get errorExtraItemInvalid => 'একটি অতিরিক্ত আইটেম সঠিক নয়।';

  @override
  String get errorExtrasPending => 'অতিরিক্ত আইটেম গ্রাহকের সম্মতির অপেক্ষায়।';

  @override
  String get errorCashConfirmationRequired =>
      'নগদ টাকা পেয়েছেন তা নিশ্চিত করুন।';

  @override
  String get errorReviewNotAllowed => 'কাজ শেষ হলে তবেই রেটিং দেওয়া যাবে।';

  @override
  String get errorReviewAlreadySubmitted =>
      'এই কাজের রেটিং আগেই দেওয়া হয়েছে।';

  @override
  String get errorUploadInvalid =>
      'এই ফাইলটি ব্যবহার করা যাবে না। অন্য ছবি দিন।';

  @override
  String get errorUploadNotFound => 'আপলোড শেষ হয়নি। আবার চেষ্টা করুন।';

  @override
  String get errorEnrolmentIncomplete => 'আগে নিবন্ধনের সব ধাপ শেষ করুন।';

  @override
  String get errorNotVerified => 'আপনার যাচাই এখনও সম্পন্ন হয়নি।';

  @override
  String get errorAgeRequirement => 'সেবাদাতার বয়স কমপক্ষে ১৮ বছর হতে হবে।';

  @override
  String get errorLevel2CoolingOff =>
      'অপেক্ষার সময় শেষে আবার লেভেল ২-এর জন্য বুক করতে পারবেন।';

  @override
  String get errorComplaintInvalidTransition =>
      'এই অভিযোগের সমাধান আগেই হয়েছে।';

  @override
  String get errorSettingInvalid => 'মানটি এই সেটিংয়ের সাথে মেলে না।';

  @override
  String get errorRoleInvalid => 'এই ভূমিকাটি সঠিক নয়।';

  @override
  String get errorProfileNotFound => 'আগে আপনার প্রোফাইল তৈরি করুন।';

  @override
  String get errorProfileRequired => 'আগে আপনার প্রোফাইল তৈরি করুন।';

  @override
  String get errorEmergencyContactMissing => 'আগে একজন জরুরি যোগাযোগ যোগ করুন।';

  @override
  String get errorServiceAreaMissing => 'আগে আপনার সেবা এলাকা ঠিক করুন।';

  @override
  String get errorOffline => 'অনুরোধ পেতে অনলাইনে যান।';

  @override
  String get errorItemNotPending => 'এই আইটেমটি যাচাইয়ের অপেক্ষায় নেই।';

  @override
  String get errorClearanceTooOld => 'পুলিশ ক্লিয়ারেন্সটি অনেক পুরোনো।';

  @override
  String get errorNidBlocked => 'এই এনআইডি পাও-তে ব্যবহার করা যাবে না।';

  @override
  String get errorLevel2NotEligible => 'আপনি এখনও লেভেল ২-এর যোগ্য নন।';

  @override
  String get errorSessionClosed => 'এই লেভেল ২ সেশনটি বন্ধ।';

  @override
  String get errorAcceptDeadlinePassed => 'গ্রহণ করার সময় পার হয়ে গেছে।';

  @override
  String get errorNoPendingExtras =>
      'সিদ্ধান্ত নেওয়ার মতো কোনো অতিরিক্ত আইটেম নেই।';

  @override
  String get actionLoadMore => 'আরও দেখুন';
}
