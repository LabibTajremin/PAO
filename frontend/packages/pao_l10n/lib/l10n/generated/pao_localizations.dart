import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'pao_localizations_bn.dart';
import 'pao_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PaoL10n
/// returned by `PaoL10n.of(context)`.
///
/// Applications need to include `PaoL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/pao_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PaoL10n.localizationsDelegates,
///   supportedLocales: PaoL10n.supportedLocales,
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
/// be consistent with the languages listed in the PaoL10n.supportedLocales
/// property.
abstract class PaoL10n {
  PaoL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PaoL10n of(BuildContext context) {
    return Localizations.of<PaoL10n>(context, PaoL10n)!;
  }

  static const LocalizationsDelegate<PaoL10n> delegate = _PaoL10nDelegate();

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

  /// Product name.
  ///
  /// In en, this message translates to:
  /// **'PAO'**
  String get appName;

  /// English language name, always in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Bangla language name, always in Bangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBangla;

  /// Retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// Continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Back button semantic label.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Link to a full list.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get actionSeeAll;

  /// Sign-out action.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get actionSignOut;

  /// C36 offline banner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. We will reconnect when the network is back.'**
  String get offlineBanner;

  /// Semantic label for skeleton loaders.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Generic empty state title.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// Generic error state title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// Shown when a role may not open a screen.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this screen.'**
  String get accessDenied;

  /// C63 title.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get sessionExpiredTitle;

  /// C63 body.
  ///
  /// In en, this message translates to:
  /// **'For your safety we signed you out. Sign in again to continue.'**
  String get sessionExpiredBody;

  /// Bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// Partner bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get navJobs;

  /// Partner bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// Bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// Bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// Semantic label of rating stars.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 5 stars'**
  String ratingLabel(String rating);

  /// Item count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// Arrival estimate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min away} other{{count} min away}}'**
  String minutesAway(int count);

  /// Network failure.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get failureNetwork;

  /// Timeout failure.
  ///
  /// In en, this message translates to:
  /// **'The network is slow. Please try again.'**
  String get failureTimeout;

  /// Session expired.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Please sign in again.'**
  String get failureSessionExpired;

  /// Fallback failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get failureUnexpected;

  /// API error VALIDATION_FAILED.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get errorValidationFailed;

  /// API error UNAUTHENTICATED.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errorUnauthenticated;

  /// API error TOKEN_EXPIRED.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Please sign in again.'**
  String get errorTokenExpired;

  /// API error FORBIDDEN.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to do this.'**
  String get errorForbidden;

  /// API error NOT_FOUND.
  ///
  /// In en, this message translates to:
  /// **'We could not find that.'**
  String get errorNotFound;

  /// API error CONFLICT.
  ///
  /// In en, this message translates to:
  /// **'This was already changed. Refresh and try again.'**
  String get errorConflict;

  /// API error RATE_LIMITED.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Please wait a little.'**
  String get errorRateLimited;

  /// API error INTERNAL.
  ///
  /// In en, this message translates to:
  /// **'Our service had a problem. Please try again.'**
  String get errorInternal;

  /// API error NOT_IMPLEMENTED.
  ///
  /// In en, this message translates to:
  /// **'This is not available yet.'**
  String get errorNotImplemented;

  /// API error OTP_INVALID.
  ///
  /// In en, this message translates to:
  /// **'That code is not right.'**
  String get errorOtpInvalid;

  /// API error OTP_EXPIRED.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Ask for a new one.'**
  String get errorOtpExpired;

  /// API error OTP_LOCKED.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Try again later.'**
  String get errorOtpLocked;

  /// API error ACCOUNT_BANNED.
  ///
  /// In en, this message translates to:
  /// **'This account has been closed.'**
  String get errorAccountBanned;

  /// API error ACCOUNT_SUSPENDED.
  ///
  /// In en, this message translates to:
  /// **'This account is suspended. Contact support.'**
  String get errorAccountSuspended;

  /// API error INVALID_CREDENTIALS.
  ///
  /// In en, this message translates to:
  /// **'Email or password is wrong.'**
  String get errorInvalidCredentials;

  /// API error ACCOUNT_LOCKED.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. The account is locked for a while.'**
  String get errorAccountLocked;

  /// API error TOTP_INVALID.
  ///
  /// In en, this message translates to:
  /// **'That authenticator code is not right.'**
  String get errorTotpInvalid;

  /// API error MFA_CHALLENGE_EXPIRED.
  ///
  /// In en, this message translates to:
  /// **'Sign-in took too long. Start again.'**
  String get errorMfaChallengeExpired;

  /// API error REFRESH_TOKEN_INVALID.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Please sign in again.'**
  String get errorRefreshTokenInvalid;

  /// API error IDEMPOTENCY_KEY_REQUIRED.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorIdempotencyKeyRequired;

  /// API error IDEMPOTENCY_KEY_REUSED.
  ///
  /// In en, this message translates to:
  /// **'This request was already sent.'**
  String get errorIdempotencyKeyReused;

  /// API error ADDRESS_LIMIT_REACHED.
  ///
  /// In en, this message translates to:
  /// **'You have saved the most addresses allowed.'**
  String get errorAddressLimitReached;

  /// API error OUTSIDE_SERVICE_AREA.
  ///
  /// In en, this message translates to:
  /// **'PAO is not available in this area yet.'**
  String get errorOutsideServiceArea;

  /// API error SERVICE_UNAVAILABLE.
  ///
  /// In en, this message translates to:
  /// **'This service is not available right now.'**
  String get errorServiceUnavailable;

  /// API error PROVIDER_UNAVAILABLE.
  ///
  /// In en, this message translates to:
  /// **'This provider is not available now.'**
  String get errorProviderUnavailable;

  /// API error DUPLICATE_BOOKING_REQUEST.
  ///
  /// In en, this message translates to:
  /// **'You already have a request with this provider.'**
  String get errorDuplicateBookingRequest;

  /// API error BOOKING_INVALID_TRANSITION.
  ///
  /// In en, this message translates to:
  /// **'This booking cannot change that way now.'**
  String get errorBookingInvalidTransition;

  /// API error BOOKING_ALREADY_RESPONDED.
  ///
  /// In en, this message translates to:
  /// **'This request was already answered.'**
  String get errorBookingAlreadyResponded;

  /// API error ACTIVE_JOB_EXISTS.
  ///
  /// In en, this message translates to:
  /// **'Finish your current job first.'**
  String get errorActiveJobExists;

  /// API error START_CODE_INVALID.
  ///
  /// In en, this message translates to:
  /// **'That start code is not right.'**
  String get errorStartCodeInvalid;

  /// API error START_CODE_LOCKED.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Try again in a few minutes.'**
  String get errorStartCodeLocked;

  /// API error CANCELLATION_NOT_ALLOWED.
  ///
  /// In en, this message translates to:
  /// **'This booking can no longer be cancelled.'**
  String get errorCancellationNotAllowed;

  /// API error EXTRA_ITEM_INVALID.
  ///
  /// In en, this message translates to:
  /// **'One of the extra items is not valid.'**
  String get errorExtraItemInvalid;

  /// API error EXTRAS_PENDING.
  ///
  /// In en, this message translates to:
  /// **'Extra items are waiting for the customer.'**
  String get errorExtrasPending;

  /// API error CASH_CONFIRMATION_REQUIRED.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you received the cash.'**
  String get errorCashConfirmationRequired;

  /// API error REVIEW_NOT_ALLOWED.
  ///
  /// In en, this message translates to:
  /// **'You can rate only after the job is done.'**
  String get errorReviewNotAllowed;

  /// API error REVIEW_ALREADY_SUBMITTED.
  ///
  /// In en, this message translates to:
  /// **'You have already rated this job.'**
  String get errorReviewAlreadySubmitted;

  /// API error UPLOAD_INVALID.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be used. Try another photo.'**
  String get errorUploadInvalid;

  /// API error UPLOAD_NOT_FOUND.
  ///
  /// In en, this message translates to:
  /// **'The upload did not finish. Try again.'**
  String get errorUploadNotFound;

  /// API error ENROLMENT_INCOMPLETE.
  ///
  /// In en, this message translates to:
  /// **'Complete every enrolment step first.'**
  String get errorEnrolmentIncomplete;

  /// API error NOT_VERIFIED.
  ///
  /// In en, this message translates to:
  /// **'Your verification is not complete yet.'**
  String get errorNotVerified;

  /// API error AGE_REQUIREMENT.
  ///
  /// In en, this message translates to:
  /// **'Providers must be at least 18 years old.'**
  String get errorAgeRequirement;

  /// API error LEVEL2_COOLING_OFF.
  ///
  /// In en, this message translates to:
  /// **'You can book Level 2 again after the waiting period.'**
  String get errorLevel2CoolingOff;

  /// API error COMPLAINT_INVALID_TRANSITION.
  ///
  /// In en, this message translates to:
  /// **'This report is already resolved.'**
  String get errorComplaintInvalidTransition;

  /// API error SETTING_INVALID.
  ///
  /// In en, this message translates to:
  /// **'This value does not fit the setting.'**
  String get errorSettingInvalid;

  /// API error ROLE_INVALID.
  ///
  /// In en, this message translates to:
  /// **'This role is not valid.'**
  String get errorRoleInvalid;

  /// API error PROFILE_NOT_FOUND.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile first.'**
  String get errorProfileNotFound;

  /// API error PROFILE_REQUIRED.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile first.'**
  String get errorProfileRequired;

  /// API error EMERGENCY_CONTACT_MISSING.
  ///
  /// In en, this message translates to:
  /// **'Add an emergency contact first.'**
  String get errorEmergencyContactMissing;

  /// API error SERVICE_AREA_MISSING.
  ///
  /// In en, this message translates to:
  /// **'Set your service area first.'**
  String get errorServiceAreaMissing;

  /// API error OFFLINE.
  ///
  /// In en, this message translates to:
  /// **'Go online to receive requests.'**
  String get errorOffline;

  /// API error ITEM_NOT_PENDING.
  ///
  /// In en, this message translates to:
  /// **'This item is not waiting for review.'**
  String get errorItemNotPending;

  /// API error CLEARANCE_TOO_OLD.
  ///
  /// In en, this message translates to:
  /// **'The police clearance is too old.'**
  String get errorClearanceTooOld;

  /// API error NID_BLOCKED.
  ///
  /// In en, this message translates to:
  /// **'This NID cannot be used on PAO.'**
  String get errorNidBlocked;

  /// API error LEVEL2_NOT_ELIGIBLE.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible for Level 2 yet.'**
  String get errorLevel2NotEligible;

  /// API error SESSION_CLOSED.
  ///
  /// In en, this message translates to:
  /// **'This Level 2 session is closed.'**
  String get errorSessionClosed;

  /// API error ACCEPT_DEADLINE_PASSED.
  ///
  /// In en, this message translates to:
  /// **'The time to accept has passed.'**
  String get errorAcceptDeadlinePassed;

  /// API error NO_PENDING_EXTRAS.
  ///
  /// In en, this message translates to:
  /// **'There are no extra items to decide on.'**
  String get errorNoPendingExtras;

  /// Button that loads the next page of a list.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get actionLoadMore;
}

class _PaoL10nDelegate extends LocalizationsDelegate<PaoL10n> {
  const _PaoL10nDelegate();

  @override
  Future<PaoL10n> load(Locale locale) {
    return SynchronousFuture<PaoL10n>(lookupPaoL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_PaoL10nDelegate old) => false;
}

PaoL10n lookupPaoL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return PaoL10nBn();
    case 'en':
      return PaoL10nEn();
  }

  throw FlutterError(
    'PaoL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
