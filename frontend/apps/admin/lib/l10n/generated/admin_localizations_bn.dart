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
}
