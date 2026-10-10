// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'customer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CustomerL10nEn extends CustomerL10n {
  CustomerL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PAO';

  @override
  String get authPhoneTitle => 'What is your phone number?';

  @override
  String get authPhoneBody => 'We will text you a code to sign in.';

  @override
  String get authPhoneLabel => 'Mobile number';

  @override
  String get authPhoneInvalid => 'Enter an 11-digit Bangladeshi mobile number.';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authTermsNote =>
      'By continuing you agree to PAO\'s terms and privacy policy.';

  @override
  String get authTermsLink => 'Read the terms and privacy policy';

  @override
  String get authOtpTitle => 'Enter the 6-digit code';

  @override
  String authOtpSentTo(String phone) {
    return 'We sent it to $phone.';
  }

  @override
  String authResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get authResend => 'Resend code';

  @override
  String get authProfileTitle => 'Set up your profile';

  @override
  String get authProfileBody =>
      'Tell providers what to call you. A photo is optional.';

  @override
  String get authProfileName => 'Your name';

  @override
  String get authProfileNameInvalid => 'Enter a name of 2 to 80 characters.';

  @override
  String get authProfileAddPhoto => 'Add a photo';

  @override
  String get onbTagline => 'Trusted help at home';

  @override
  String get onbLanguage => 'Language';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbSlide1Title => 'Find help nearby';

  @override
  String get onbSlide1Body =>
      'Electricians, plumbers, cleaners and more, close to your home.';

  @override
  String get onbSlide2Title => 'Verified providers';

  @override
  String get onbSlide2Body =>
      'Every provider\'s NID, police clearance and skills are checked before they work.';

  @override
  String get onbSlide3Title => 'Fixed prices, pay in cash';

  @override
  String get onbSlide3Body =>
      'See the price before you book. Pay the provider in cash when the job is done.';
}
