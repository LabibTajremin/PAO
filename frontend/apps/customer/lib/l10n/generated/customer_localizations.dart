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

  /// C12 title
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get bookingSetupTitle;

  /// Setup opened without a provider or items
  ///
  /// In en, this message translates to:
  /// **'Nothing to book yet'**
  String get bookingNothingTitle;

  /// Setup without a draft, explanation
  ///
  /// In en, this message translates to:
  /// **'Choose a service and a provider first.'**
  String get bookingNothingBody;

  /// Button to the service list
  ///
  /// In en, this message translates to:
  /// **'Browse services'**
  String get bookingBrowse;

  /// Bill total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingTotal;

  /// A bill line: item name and quantity
  ///
  /// In en, this message translates to:
  /// **'{name} × {count}'**
  String bookingLine(String name, String count);

  /// Badge on an item added during the job
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get bookingExtra;

  /// Provider rating and number of reviews
  ///
  /// In en, this message translates to:
  /// **'★ {rating} ({count})'**
  String bookingRating(String rating, String count);

  /// Provider badge
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get bookingBadgeVerified;

  /// Provider badge, level 2
  ///
  /// In en, this message translates to:
  /// **'Verified Pro'**
  String get bookingBadgePro;

  /// C12 timing section
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get bookingWhenTitle;

  /// Timing option ASAP (C45)
  ///
  /// In en, this message translates to:
  /// **'As soon as possible'**
  String get bookingAsap;

  /// Timing option scheduled (C12)
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get bookingScheduled;

  /// Scheduled time not chosen yet
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time'**
  String get bookingPickTime;

  /// Invalid scheduled time
  ///
  /// In en, this message translates to:
  /// **'Pick a time at least 1 hour from now and within 30 days.'**
  String get bookingTimeInvalid;

  /// C12 address section
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get bookingWhereTitle;

  /// Change the address
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get bookingChange;

  /// No saved address yet
  ///
  /// In en, this message translates to:
  /// **'Add an address so the provider can find you.'**
  String get bookingNoAddress;

  /// Button to add an address
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get bookingAddAddress;

  /// C46 sheet title
  ///
  /// In en, this message translates to:
  /// **'Choose address'**
  String get bookingAddressTitle;

  /// Badge on the default address
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get bookingDefault;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bookingLabelHome;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get bookingLabelOffice;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get bookingLabelOther;

  /// Note field label
  ///
  /// In en, this message translates to:
  /// **'Note for the provider (optional)'**
  String get bookingNoteLabel;

  /// Note field hint
  ///
  /// In en, this message translates to:
  /// **'Gate code, floor, landmark…'**
  String get bookingNoteHint;

  /// C12 payment section
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get bookingPaymentTitle;

  /// Payment method
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get bookingCash;

  /// Payment explanation
  ///
  /// In en, this message translates to:
  /// **'Pay the provider in cash when the job is done.'**
  String get bookingCashBody;

  /// Confirm button with the total
  ///
  /// In en, this message translates to:
  /// **'Confirm booking · {amount}'**
  String bookingConfirm(String amount);

  /// Button to the home tab
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get bookingBackHome;

  /// C13 title
  ///
  /// In en, this message translates to:
  /// **'Booking request'**
  String get bookingWaitingTitle;

  /// C13 heading
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to accept'**
  String bookingWaitingHeading(String name);

  /// C13 explanation
  ///
  /// In en, this message translates to:
  /// **'We will let you know as soon as the provider answers.'**
  String get bookingWaitingBody;

  /// C13 cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get bookingWaitingCancel;

  /// C47 title
  ///
  /// In en, this message translates to:
  /// **'{name} can\'t take this job'**
  String bookingWaitingDeclinedTitle(String name);

  /// C13b title
  ///
  /// In en, this message translates to:
  /// **'No answer in time'**
  String get bookingWaitingTimedOutTitle;

  /// C47 and C13b explanation
  ///
  /// In en, this message translates to:
  /// **'Choose another provider nearby. Your items are kept.'**
  String get bookingWaitingMissedBody;

  /// C47 and C13b button
  ///
  /// In en, this message translates to:
  /// **'Choose another provider'**
  String get bookingWaitingChooseAnother;

  /// C48 title
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmedTitle;

  /// C48 heading
  ///
  /// In en, this message translates to:
  /// **'Your provider accepted. See you then!'**
  String get bookingConfirmedHeading;

  /// C48 button to the detail
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get bookingConfirmedView;

  /// C14 title
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get liveTitle;

  /// Call button tooltip
  ///
  /// In en, this message translates to:
  /// **'Call provider'**
  String get liveCall;

  /// Status step
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get liveStepAccepted;

  /// Status step
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get liveStepOnTheWay;

  /// Status step
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get liveStepArrived;

  /// Status step
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get liveStepInProgress;

  /// Status step
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get liveStepCompleted;

  /// C49 heading
  ///
  /// In en, this message translates to:
  /// **'{name} accepted your booking'**
  String liveAcceptedTitle(String name);

  /// C49 hint
  ///
  /// In en, this message translates to:
  /// **'They will set off soon. Keep your start code ready.'**
  String get liveAcceptedHint;

  /// C14 heading
  ///
  /// In en, this message translates to:
  /// **'{name} is on the way'**
  String liveOnTheWayTitle(String name);

  /// C50 heading
  ///
  /// In en, this message translates to:
  /// **'{name} has arrived'**
  String liveArrivedTitle(String name);

  /// C50 hint
  ///
  /// In en, this message translates to:
  /// **'Read out the start code so the job can begin.'**
  String get liveArrivedHint;

  /// C51 heading
  ///
  /// In en, this message translates to:
  /// **'Job in progress'**
  String get liveInProgressTitle;

  /// C51 hint
  ///
  /// In en, this message translates to:
  /// **'Extra items need your approval before they are added.'**
  String get liveInProgressHint;

  /// Scheduled start
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {when}'**
  String liveScheduledFor(String when);

  /// Start code card heading
  ///
  /// In en, this message translates to:
  /// **'Start code'**
  String get liveCodeTitle;

  /// Start code advice
  ///
  /// In en, this message translates to:
  /// **'Share the code only when the provider is with you.'**
  String get liveCodeHint;

  /// Screen reader label of the code
  ///
  /// In en, this message translates to:
  /// **'Start code {digits}'**
  String liveCodeSemantics(String digits);

  /// Pending extras card title
  ///
  /// In en, this message translates to:
  /// **'Extra items to approve'**
  String get liveExtrasNoticeTitle;

  /// Pending extras card body
  ///
  /// In en, this message translates to:
  /// **'Your provider added {amount} of items.'**
  String liveExtrasNoticeBody(String amount);

  /// Pending extras card action
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get liveExtrasNoticeReview;

  /// Cancel button on the live booking
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get liveCancel;

  /// Report button
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get liveReport;

  /// C15 title
  ///
  /// In en, this message translates to:
  /// **'Extra items'**
  String get liveApprovalTitle;

  /// C15 heading
  ///
  /// In en, this message translates to:
  /// **'Your provider added items'**
  String get liveApprovalHeading;

  /// C15 explanation
  ///
  /// In en, this message translates to:
  /// **'Prices are fixed by PAO. Nothing is added without your approval.'**
  String get liveApprovalBody;

  /// Total of the extras
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get liveApprovalAdded;

  /// Booking total with the extras
  ///
  /// In en, this message translates to:
  /// **'New total'**
  String get liveApprovalNewTotal;

  /// C15 approve
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get liveApprovalApprove;

  /// C15 decline
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get liveApprovalDecline;

  /// C15 with nothing pending
  ///
  /// In en, this message translates to:
  /// **'No extra items are waiting for you.'**
  String get liveApprovalNone;

  /// C16 title
  ///
  /// In en, this message translates to:
  /// **'Job completed'**
  String get liveCompletedTitle;

  /// C16 heading
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get liveCompletedHeading;

  /// C16 amount to pay
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} in cash'**
  String liveCompletedPay(String amount);

  /// C16 payment instruction
  ///
  /// In en, this message translates to:
  /// **'Hand the cash to {name}.'**
  String liveCompletedPayBody(String name);

  /// C16 once the provider confirmed the cash
  ///
  /// In en, this message translates to:
  /// **'{amount} paid in cash'**
  String liveCompletedPaid(String amount);

  /// C16 button to rating
  ///
  /// In en, this message translates to:
  /// **'Rate {name}'**
  String liveCompletedRate(String name);

  /// C16 button to the receipt
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get liveCompletedReceipt;

  /// C52 title
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelTitle;

  /// C52 heading
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get cancelQuestion;

  /// C52 policy note
  ///
  /// In en, this message translates to:
  /// **'Cancelling is free until the job starts.'**
  String get cancelFree;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'I changed my mind'**
  String get cancelReasonChangedMind;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'I found another provider'**
  String get cancelReasonOtherProvider;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'The provider is late'**
  String get cancelReasonLate;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'I booked by mistake'**
  String get cancelReasonMistake;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get cancelReasonOther;

  /// Cancel note label
  ///
  /// In en, this message translates to:
  /// **'Anything to add? (optional)'**
  String get cancelNote;

  /// C52 confirm
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelConfirm;

  /// C52 keep
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get cancelKeep;

  /// C53 title
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get cancelDoneTitle;

  /// C53 explanation
  ///
  /// In en, this message translates to:
  /// **'No charge. You can book another provider any time.'**
  String get cancelDoneBody;

  /// C53 button
  ///
  /// In en, this message translates to:
  /// **'Book another provider'**
  String get cancelBookAgain;

  /// C54 title
  ///
  /// In en, this message translates to:
  /// **'The job has already started'**
  String get cancelBlockedTitle;

  /// C54 explanation
  ///
  /// In en, this message translates to:
  /// **'A booking can\'t be cancelled after the start code is entered. If something is wrong, report a problem.'**
  String get cancelBlockedBody;

  /// Cancel opened on a declined or expired booking
  ///
  /// In en, this message translates to:
  /// **'This booking is no longer active'**
  String get cancelClosedTitle;

  /// C17 title
  ///
  /// In en, this message translates to:
  /// **'Rate provider'**
  String get ratingTitle;

  /// C17 heading
  ///
  /// In en, this message translates to:
  /// **'How was {name}?'**
  String ratingQuestion(String name);

  /// C17 comment label
  ///
  /// In en, this message translates to:
  /// **'Tell others more (optional)'**
  String get ratingComment;

  /// C17 submit
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get ratingSubmit;

  /// C17 skip
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get ratingSkip;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get ratingTagOnTime;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get ratingTagProfessional;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Quality work'**
  String get ratingTagQuality;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get ratingTagClean;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get ratingTagFriendly;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Fair price'**
  String get ratingTagFairPrice;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get ratingTagLate;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Rude'**
  String get ratingTagRude;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Poor quality'**
  String get ratingTagPoorQuality;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Messy'**
  String get ratingTagMessy;

  /// C55 title
  ///
  /// In en, this message translates to:
  /// **'Thanks for your rating!'**
  String get ratingThanksTitle;

  /// C55 body
  ///
  /// In en, this message translates to:
  /// **'Your feedback keeps PAO safe and reliable.'**
  String get ratingThanksBody;

  /// C55 button
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get ratingMyBookings;

  /// Booking screen could not refresh
  ///
  /// In en, this message translates to:
  /// **'Showing the last known status. We will update it when you are back online.'**
  String get connectivityStale;

  /// Live booking offline with a cached code
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your start code is saved on this phone.'**
  String get connectivityCodeSaved;
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
