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
}
