import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'admin_localizations_bn.dart';
import 'admin_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AdminL10n
/// returned by `AdminL10n.of(context)`.
///
/// Applications need to include `AdminL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/admin_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AdminL10n.localizationsDelegates,
///   supportedLocales: AdminL10n.supportedLocales,
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
/// be consistent with the languages listed in the AdminL10n.supportedLocales
/// property.
abstract class AdminL10n {
  AdminL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AdminL10n of(BuildContext context) {
    return Localizations.of<AdminL10n>(context, AdminL10n)!;
  }

  static const LocalizationsDelegate<AdminL10n> delegate = _AdminL10nDelegate();

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

  /// Panel name
  ///
  /// In en, this message translates to:
  /// **'PAO Admin'**
  String get appTitle;

  /// Menu: A02
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Menu: A05
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get navVerification;

  /// Menu: A07
  ///
  /// In en, this message translates to:
  /// **'Level 2 sessions'**
  String get navLevel2;

  /// Menu: A03
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get navCatalog;

  /// Menu: A08
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get navProviders;

  /// Menu: A09
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// Menu: A10
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// Menu: A11
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get navComplaints;

  /// Menu: A12
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// A01 heading
  ///
  /// In en, this message translates to:
  /// **'Sign in to PAO Admin'**
  String get loginTitle;

  /// A01 email field
  ///
  /// In en, this message translates to:
  /// **'Work email'**
  String get loginEmail;

  /// A01 password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// A01 button
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSubmit;

  /// A01 TOTP enrolment
  ///
  /// In en, this message translates to:
  /// **'First sign-in: add this key to your authenticator app.'**
  String get loginEnrolBody;

  /// A01 code step
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app.'**
  String get loginCodeBody;

  /// A01 back to the password step
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get loginBack;

  /// Password change heading
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get passwordTitle;

  /// Password change explanation
  ///
  /// In en, this message translates to:
  /// **'Replace the temporary password from your invitation before you continue.'**
  String get passwordBody;

  /// Password field
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get passwordCurrent;

  /// Password field
  ///
  /// In en, this message translates to:
  /// **'New password (at least 12 characters)'**
  String get passwordNew;

  /// Password field
  ///
  /// In en, this message translates to:
  /// **'Repeat the new password'**
  String get passwordRepeat;

  /// Password too short
  ///
  /// In en, this message translates to:
  /// **'The new password needs at least 12 characters.'**
  String get passwordTooShort;

  /// Password mismatch
  ///
  /// In en, this message translates to:
  /// **'The two new passwords are not the same.'**
  String get passwordMismatch;

  /// Confirm-with-reason field
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// Reason too short
  ///
  /// In en, this message translates to:
  /// **'Write at least {count} characters.'**
  String reasonTooShort(int count);
}

class _AdminL10nDelegate extends LocalizationsDelegate<AdminL10n> {
  const _AdminL10nDelegate();

  @override
  Future<AdminL10n> load(Locale locale) {
    return SynchronousFuture<AdminL10n>(lookupAdminL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AdminL10nDelegate old) => false;
}

AdminL10n lookupAdminL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AdminL10nBn();
    case 'en':
      return AdminL10nEn();
  }

  throw FlutterError(
    'AdminL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
