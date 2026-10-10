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
  String get homeOnline => 'আপনি অনলাইনে আছেন';

  @override
  String get homeOffline => 'আপনি অফলাইনে আছেন';

  @override
  String get homeOnlineBody => 'কাছের গ্রাহকরা আপনাকে অনুরোধ পাঠাতে পারবেন।';

  @override
  String get homeOfflineBody => 'অনুরোধ পেতে অনলাইনে যান।';

  @override
  String get homeLocationOff =>
      'অনলাইনে যেতে লোকেশন চালু করুন। শুধু অনলাইনে থাকার সময় এটি শেয়ার হয়।';

  @override
  String get homePausedTitle => 'অনুরোধ বন্ধ আছে';

  @override
  String get homePausedBody =>
      'একটি কাগজের মেয়াদ শেষ হয়েছে। আবার অনুরোধ পেতে এটি নবায়ন করুন।';

  @override
  String get homeRenew => 'কাগজ নবায়ন করুন';

  @override
  String homeExpiring(String date) {
    return '$date তারিখে একটি কাগজের মেয়াদ শেষ হবে। অনুরোধ পেতে থাকতে এটি নবায়ন করুন।';
  }

  @override
  String get homeToday => 'আজকের আয়';

  @override
  String homeJobsToday(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'আজ $countStringটি কাজ',
    );
    return '$_temp0';
  }

  @override
  String get homeActiveJob => 'চলমান কাজ';

  @override
  String get homeRequests => 'নতুন অনুরোধ';

  @override
  String get homeNoRequests => 'এখন কোনো অনুরোধ নেই';

  @override
  String get homeNoRequestsBody => 'কাছের অনুরোধ পেতে অনলাইনে থাকুন।';

  @override
  String get reqTitle => 'নতুন অনুরোধ';

  @override
  String reqTimeLeft(String time) {
    return 'উত্তর দিতে $time বাকি';
  }

  @override
  String get reqAsap => 'যত তাড়াতাড়ি সম্ভব';

  @override
  String reqScheduled(String time) {
    return '$time সময়ের জন্য নির্ধারিত';
  }

  @override
  String reqDistance(String km) {
    return '$km কিমি দূরে';
  }

  @override
  String get reqNote => 'গ্রাহকের নোট';

  @override
  String get reqAccept => 'গ্রহণ করুন';

  @override
  String get reqReject => 'প্রত্যাখ্যান করুন';

  @override
  String get reqRejectTitle => 'কেন প্রত্যাখ্যান করছেন?';

  @override
  String get reqReasonBusy => 'আমি ব্যস্ত';

  @override
  String get reqReasonTooFar => 'অনেক দূরে';

  @override
  String get reqReasonNotMyService => 'এটি আমার সেবা নয়';

  @override
  String get reqReasonOther => 'অন্য কারণ';

  @override
  String get reqExpiredTitle => 'এই অনুরোধটি আর খোলা নেই';

  @override
  String get reqExpiredBody =>
      'উত্তর দেওয়ার সময় শেষ হয়েছে অথবা এর উত্তর আগেই দেওয়া হয়েছে।';

  @override
  String get jobLiveTitle => 'চলমান কাজ';

  @override
  String get jobStatusRequested => 'আপনার উত্তরের অপেক্ষায়';

  @override
  String get jobStepAccepted => 'গৃহীত';

  @override
  String get jobStepOnTheWay => 'পথে আছেন';

  @override
  String get jobStepArrived => 'পৌঁছেছেন';

  @override
  String get jobStepStarted => 'কাজ শুরু হয়েছে';

  @override
  String get jobStepCompleted => 'সম্পন্ন';

  @override
  String get jobStatusCancelled => 'বাতিল';

  @override
  String get jobStatusClosed => 'বন্ধ';

  @override
  String get jobCustomer => 'গ্রাহক';

  @override
  String get jobActionNavigate => 'দিকনির্দেশনা';

  @override
  String get jobActionCall => 'কল করুন';

  @override
  String get jobActionOnTheWay => 'আমি রওনা দিয়েছি';

  @override
  String get jobActionArrived => 'আমি পৌঁছেছি';

  @override
  String get jobActionStart => 'শুরুর কোড দিন';

  @override
  String get jobActionExtras => 'অতিরিক্ত আইটেম যোগ করুন';

  @override
  String get jobActionComplete => 'কাজ সম্পন্ন করুন';

  @override
  String get jobActionRate => 'গ্রাহককে রেটিং দিন';

  @override
  String get jobActionOpenRequest => 'অনুরোধ খুলুন';

  @override
  String get jobActionCancel => 'কাজ বাতিল করুন';

  @override
  String get jobBackHome => 'হোমে ফিরে যান';

  @override
  String get jobBackToJob => 'কাজে ফিরে যান';

  @override
  String get jobTotal => 'মোট';

  @override
  String jobQuantity(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'পরিমাণ $countString';
  }

  @override
  String jobExtraQuantity(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'অতিরিক্ত · পরিমাণ $countString';
  }

  @override
  String get jobCancelTitle => 'কেন বাতিল করছেন?';

  @override
  String get jobCancelWarning =>
      'গ্রহণের পর বাতিল করলে আপনার র‍্যাঙ্কিং কমে যায়।';

  @override
  String get jobCancelEmergency => 'জরুরি অবস্থা';

  @override
  String get jobCancelUnreachable => 'গ্রাহককে পাওয়া যাচ্ছে না';

  @override
  String get jobCancelUnsafe => 'অনিরাপদ জায়গা';

  @override
  String get jobCancelOther => 'অন্য কারণ';

  @override
  String get jobNoteLabel => 'নোট (ঐচ্ছিক)';

  @override
  String get jobCancelledTitle => 'এই কাজটি বাতিল হয়েছে';

  @override
  String get jobCancelledByCustomer => 'গ্রাহক এই কাজটি বাতিল করেছেন।';

  @override
  String get jobCancelledOther => 'এটিতে আর কাজ করা যাবে না।';

  @override
  String get jobClosedTitle => 'এই কাজটি আর চালু নেই';

  @override
  String get jobStartTitle => 'শুরুর কোড দিন';

  @override
  String get jobStartBody =>
      'গ্রাহকের অ্যাপে থাকা ৪ সংখ্যার কোডটি তাঁর কাছ থেকে নিন।';

  @override
  String get jobExtrasTitle => 'অতিরিক্ত আইটেম যোগ করুন';

  @override
  String get jobExtrasEmpty => 'এই সেবার জন্য কোনো অতিরিক্ত আইটেম নেই।';

  @override
  String jobExtrasSend(String amount) {
    return 'গ্রাহকের কাছে পাঠান · $amount';
  }

  @override
  String get jobExtrasWaitingTitle => 'গ্রাহকের অনুমোদনের অপেক্ষায়';

  @override
  String jobExtrasWaiting(String amount) {
    return 'গ্রাহককে $amount মূল্যের অতিরিক্ত আইটেম অনুমোদন করতে বলা হয়েছে।';
  }

  @override
  String get jobExtrasApproved =>
      'গ্রাহক শেষ অতিরিক্ত আইটেমগুলো অনুমোদন করেছেন।';

  @override
  String get jobExtrasDeclined =>
      'গ্রাহক শেষ অতিরিক্ত আইটেমগুলো প্রত্যাখ্যান করেছেন।';

  @override
  String get jobCompleteTitle => 'কাজ সম্পন্ন করুন';

  @override
  String jobCashReceived(String amount) {
    return 'আমি নগদ $amount পেয়েছি';
  }

  @override
  String get jobRateTitle => 'গ্রাহককে রেটিং দিন';

  @override
  String get jobRateQuestion => 'এই গ্রাহক কেমন ছিলেন?';

  @override
  String jobRateStars(int stars) {
    final intl.NumberFormat starsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String starsString = starsNumberFormat.format(stars);

    return '৫-এর মধ্যে $starsString তারা';
  }

  @override
  String get jobRateComment => 'মন্তব্য (ঐচ্ছিক)';

  @override
  String get jobRateSubmit => 'রেটিং জমা দিন';

  @override
  String get jobRateSkip => 'এড়িয়ে যান';

  @override
  String get jobTagPolite => 'ভদ্র';

  @override
  String get jobTagClearInstructions => 'স্পষ্ট নির্দেশনা';

  @override
  String get jobTagPaidPromptly => 'সময়মতো টাকা দিয়েছেন';

  @override
  String get jobTagSafePlace => 'নিরাপদ জায়গা';

  @override
  String get jobTagRude => 'অভদ্র';

  @override
  String get jobTagUnclearInstructions => 'অস্পষ্ট নির্দেশনা';

  @override
  String get jobTagUnsafePlace => 'অনিরাপদ জায়গা';

  @override
  String get notifReadAll => 'সব পড়া হয়েছে';

  @override
  String get notifEmpty => 'এখনো কোনো নোটিফিকেশন নেই';

  @override
  String get notifEmptyBody => 'অনুরোধ, কাজ ও কাগজপত্রের খবর এখানে দেখাবে।';
}
