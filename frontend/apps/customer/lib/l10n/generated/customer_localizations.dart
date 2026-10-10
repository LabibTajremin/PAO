import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'customer_localizations_bn.dart';
import 'customer_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CustomerL10n
/// returned by `CustomerL10n.of(context)`.
///
/// Applications need to include `CustomerL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/customer_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CustomerL10n.localizationsDelegates,
///   supportedLocales: CustomerL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the CustomerL10n.supportedLocales
/// property.
abstract class CustomerL10n {
  CustomerL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CustomerL10n of(BuildContext context) {
    return Localizations.of<CustomerL10n>(context, CustomerL10n)!;
  }

  static const LocalizationsDelegate<CustomerL10n> delegate =
      _CustomerL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// App name on the splash
  ///
  /// In en, this message translates to:
  /// **'PAO'**
  String get appTitle;

  /// C03 heading
  ///
  /// In en, this message translates to:
  /// **'What is your phone number?'**
  String get authPhoneTitle;

  /// C03 explanation
  ///
  /// In en, this message translates to:
  /// **'We will text you a code to sign in.'**
  String get authPhoneBody;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authPhoneLabel;

  /// Invalid phone number
  ///
  /// In en, this message translates to:
  /// **'Enter an 11-digit Bangladeshi mobile number.'**
  String get authPhoneInvalid;

  /// C03 button
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// C03 consent note
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to PAO\'s terms and privacy policy.'**
  String get authTermsNote;

  /// C03 link to C28
  ///
  /// In en, this message translates to:
  /// **'Read the terms and privacy policy'**
  String get authTermsLink;

  /// C04 heading
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authOtpTitle;

  /// C04 explanation
  ///
  /// In en, this message translates to:
  /// **'We sent it to {phone}.'**
  String authOtpSentTo(String phone);

  /// Resend countdown
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String authResendIn(int seconds);

  /// Resend button
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResend;

  /// C05 heading
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get authProfileTitle;

  /// C05 explanation
  ///
  /// In en, this message translates to:
  /// **'Tell providers what to call you. A photo is optional.'**
  String get authProfileBody;

  /// C05 name field
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authProfileName;

  /// C05 invalid name
  ///
  /// In en, this message translates to:
  /// **'Enter a name of 2 to 80 characters.'**
  String get authProfileNameInvalid;

  /// C05 photo button
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get authProfileAddPhoto;

  /// Splash tagline
  ///
  /// In en, this message translates to:
  /// **'Trusted help at home'**
  String get onbTagline;

  /// Language switch label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onbLanguage;

  /// Skip onboarding
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// Next slide
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// Finish onboarding
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbStart;

  /// C02 title
  ///
  /// In en, this message translates to:
  /// **'Find help nearby'**
  String get onbSlide1Title;

  /// C02 body
  ///
  /// In en, this message translates to:
  /// **'Electricians, plumbers, cleaners and more, close to your home.'**
  String get onbSlide1Body;

  /// C31 title
  ///
  /// In en, this message translates to:
  /// **'Verified providers'**
  String get onbSlide2Title;

  /// C31 body
  ///
  /// In en, this message translates to:
  /// **'Every provider\'s NID, police clearance and skills are checked before they work.'**
  String get onbSlide2Body;

  /// C32 title
  ///
  /// In en, this message translates to:
  /// **'Fixed prices, pay in cash'**
  String get onbSlide3Title;

  /// C32 body
  ///
  /// In en, this message translates to:
  /// **'See the price before you book. Pay the provider in cash when the job is done.'**
  String get onbSlide3Body;
}

class _CustomerL10nDelegate extends LocalizationsDelegate<CustomerL10n> {
  const _CustomerL10nDelegate();

  @override
  Future<CustomerL10n> load(Locale locale) {
    return SynchronousFuture<CustomerL10n>(lookupCustomerL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_CustomerL10nDelegate old) => false;
}

CustomerL10n lookupCustomerL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return CustomerL10nBn();
    case 'en':
      return CustomerL10nEn();
  }

  throw FlutterError(
    'CustomerL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
