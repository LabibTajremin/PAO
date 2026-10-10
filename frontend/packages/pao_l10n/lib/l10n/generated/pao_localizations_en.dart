// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'pao_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PaoL10nEn extends PaoL10n {
  PaoL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PAO';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSeeAll => 'See all';

  @override
  String get actionSignOut => 'Log out';

  @override
  String get offlineBanner =>
      'You are offline. We will reconnect when the network is back.';

  @override
  String get loading => 'Loading';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get accessDenied => 'You do not have access to this screen.';

  @override
  String get sessionExpiredTitle => 'Welcome back';

  @override
  String get sessionExpiredBody =>
      'For your safety we signed you out. Sign in again to continue.';

  @override
  String get navHome => 'Home';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navJobs => 'Jobs';

  @override
  String get navEarnings => 'Earnings';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navAccount => 'Account';

  @override
  String ratingLabel(String rating) {
    return '$rating out of 5 stars';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String minutesAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min away',
      one: '1 min away',
    );
    return '$_temp0';
  }

  @override
  String get failureNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get failureTimeout => 'The network is slow. Please try again.';

  @override
  String get failureSessionExpired =>
      'Your session ended. Please sign in again.';

  @override
  String get failureUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorValidationFailed => 'Please check the highlighted fields.';

  @override
  String get errorUnauthenticated => 'Please sign in again.';

  @override
  String get errorTokenExpired => 'Your session ended. Please sign in again.';

  @override
  String get errorForbidden => 'You are not allowed to do this.';

  @override
  String get errorNotFound => 'We could not find that.';

  @override
  String get errorConflict =>
      'This was already changed. Refresh and try again.';

  @override
  String get errorRateLimited => 'Too many tries. Please wait a little.';

  @override
  String get errorInternal => 'Our service had a problem. Please try again.';

  @override
  String get errorNotImplemented => 'This is not available yet.';

  @override
  String get errorOtpInvalid => 'That code is not right.';

  @override
  String get errorOtpExpired => 'That code has expired. Ask for a new one.';

  @override
  String get errorOtpLocked => 'Too many wrong codes. Try again later.';

  @override
  String get errorAccountBanned => 'This account has been closed.';

  @override
  String get errorAccountSuspended =>
      'This account is suspended. Contact support.';

  @override
  String get errorInvalidCredentials => 'Email or password is wrong.';

  @override
  String get errorAccountLocked =>
      'Too many attempts. The account is locked for a while.';

  @override
  String get errorTotpInvalid => 'That authenticator code is not right.';

  @override
  String get errorMfaChallengeExpired => 'Sign-in took too long. Start again.';

  @override
  String get errorRefreshTokenInvalid =>
      'Your session ended. Please sign in again.';

  @override
  String get errorIdempotencyKeyRequired =>
      'Something went wrong. Please try again.';

  @override
  String get errorIdempotencyKeyReused => 'This request was already sent.';

  @override
  String get errorAddressLimitReached =>
      'You have saved the most addresses allowed.';

  @override
  String get errorOutsideServiceArea =>
      'PAO is not available in this area yet.';

  @override
  String get errorServiceUnavailable =>
      'This service is not available right now.';

  @override
  String get errorProviderUnavailable => 'This provider is not available now.';

  @override
  String get errorDuplicateBookingRequest =>
      'You already have a request with this provider.';

  @override
  String get errorBookingInvalidTransition =>
      'This booking cannot change that way now.';

  @override
  String get errorBookingAlreadyResponded =>
      'This request was already answered.';

  @override
  String get errorActiveJobExists => 'Finish your current job first.';

  @override
  String get errorStartCodeInvalid => 'That start code is not right.';

  @override
  String get errorStartCodeLocked =>
      'Too many wrong codes. Try again in a few minutes.';

  @override
  String get errorCancellationNotAllowed =>
      'This booking can no longer be cancelled.';

  @override
  String get errorExtraItemInvalid => 'One of the extra items is not valid.';

  @override
  String get errorExtrasPending => 'Extra items are waiting for the customer.';

  @override
  String get errorCashConfirmationRequired =>
      'Confirm that you received the cash.';

  @override
  String get errorReviewNotAllowed =>
      'You can rate only after the job is done.';

  @override
  String get errorReviewAlreadySubmitted => 'You have already rated this job.';

  @override
  String get errorUploadInvalid =>
      'This file cannot be used. Try another photo.';

  @override
  String get errorUploadNotFound => 'The upload did not finish. Try again.';

  @override
  String get errorEnrolmentIncomplete => 'Complete every enrolment step first.';

  @override
  String get errorNotVerified => 'Your verification is not complete yet.';

  @override
  String get errorAgeRequirement => 'Providers must be at least 18 years old.';

  @override
  String get errorLevel2CoolingOff =>
      'You can book Level 2 again after the waiting period.';

  @override
  String get errorComplaintInvalidTransition =>
      'This report is already resolved.';

  @override
  String get errorSettingInvalid => 'This value does not fit the setting.';

  @override
  String get errorRoleInvalid => 'This role is not valid.';

  @override
  String get errorProfileNotFound => 'Set up your profile first.';

  @override
  String get errorProfileRequired => 'Set up your profile first.';

  @override
  String get errorEmergencyContactMissing => 'Add an emergency contact first.';

  @override
  String get errorServiceAreaMissing => 'Set your service area first.';

  @override
  String get errorOffline => 'Go online to receive requests.';

  @override
  String get errorItemNotPending => 'This item is not waiting for review.';

  @override
  String get errorClearanceTooOld => 'The police clearance is too old.';

  @override
  String get errorNidBlocked => 'This NID cannot be used on PAO.';

  @override
  String get errorLevel2NotEligible => 'You are not eligible for Level 2 yet.';

  @override
  String get errorSessionClosed => 'This Level 2 session is closed.';

  @override
  String get errorAcceptDeadlinePassed => 'The time to accept has passed.';

  @override
  String get errorNoPendingExtras => 'There are no extra items to decide on.';

  @override
  String get actionLoadMore => 'Load more';
}
