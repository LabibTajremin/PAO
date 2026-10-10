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

  /// C18 title
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get bookingsTitle;

  /// C18 tab
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingsUpcoming;

  /// C18b tab
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get bookingsPast;

  /// C58 title
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings'**
  String get bookingsEmptyUpcoming;

  /// C58 body
  ///
  /// In en, this message translates to:
  /// **'Book a verified provider and the booking will show up here.'**
  String get bookingsEmptyUpcomingBody;

  /// Empty past tab title
  ///
  /// In en, this message translates to:
  /// **'No past bookings yet'**
  String get bookingsEmptyPast;

  /// Empty past tab body
  ///
  /// In en, this message translates to:
  /// **'Finished and cancelled bookings will appear here.'**
  String get bookingsEmptyPastBody;

  /// C58 button
  ///
  /// In en, this message translates to:
  /// **'Book a service'**
  String get bookingsBookService;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Waiting for reply'**
  String get bookingsStatusRequested;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get bookingsStatusAccepted;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get bookingsStatusOnTheWay;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get bookingsStatusArrived;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get bookingsStatusInProgress;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingsStatusCompleted;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get bookingsStatusRejected;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'No response'**
  String get bookingsStatusTimedOut;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingsStatusCancelled;

  /// C19 title
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get bookingsDetailTitle;

  /// C19 provider heading
  ///
  /// In en, this message translates to:
  /// **'Your provider'**
  String get bookingsProvider;

  /// C19 call button tooltip
  ///
  /// In en, this message translates to:
  /// **'Call provider'**
  String get bookingsCallProvider;

  /// Provider rating line
  ///
  /// In en, this message translates to:
  /// **'{rating} rating · {count} reviews'**
  String bookingsRatingSummary(String rating, String count);

  /// C19 address heading
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bookingsAddress;

  /// C19 note heading
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get bookingsNote;

  /// C19 timeline heading
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get bookingsTimeline;

  /// C19 bill heading
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get bookingsBill;

  /// Extra item note
  ///
  /// In en, this message translates to:
  /// **'Added during the job'**
  String get bookingsExtra;

  /// Bill total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingsTotal;

  /// Cash payment note
  ///
  /// In en, this message translates to:
  /// **'Pay the provider in cash when the job is done.'**
  String get bookingsPayCash;

  /// Paid note on completed bookings
  ///
  /// In en, this message translates to:
  /// **'Paid in cash'**
  String get bookingsPaidCash;

  /// Opens C14
  ///
  /// In en, this message translates to:
  /// **'Track live'**
  String get bookingsTrack;

  /// Opens C13
  ///
  /// In en, this message translates to:
  /// **'See request status'**
  String get bookingsWaiting;

  /// Opens C64
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get bookingsReceipt;

  /// Opens C17
  ///
  /// In en, this message translates to:
  /// **'Rate provider'**
  String get bookingsRate;

  /// Opens the service
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get bookingsBookAgain;

  /// Opens C20
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get bookingsReport;

  /// C57 heading
  ///
  /// In en, this message translates to:
  /// **'This booking was cancelled'**
  String get bookingsCancelledTitle;

  /// Declined heading
  ///
  /// In en, this message translates to:
  /// **'The provider declined this booking'**
  String get bookingsRejectedTitle;

  /// Timed-out heading
  ///
  /// In en, this message translates to:
  /// **'The provider did not answer in time'**
  String get bookingsTimedOutTitle;

  /// C57 who cancelled
  ///
  /// In en, this message translates to:
  /// **'You cancelled it.'**
  String get bookingsCancelledByYou;

  /// C57 who cancelled
  ///
  /// In en, this message translates to:
  /// **'The provider cancelled it.'**
  String get bookingsCancelledByProvider;

  /// C57 who cancelled
  ///
  /// In en, this message translates to:
  /// **'PAO cancelled it.'**
  String get bookingsCancelledByPao;

  /// C57 reason
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String bookingsEndedReason(String reason);

  /// C57 note
  ///
  /// In en, this message translates to:
  /// **'You were not charged.'**
  String get bookingsNoCharge;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'Changed my mind'**
  String get bookingsReasonChangedMind;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'Found another provider'**
  String get bookingsReasonFoundOther;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'Provider was late'**
  String get bookingsReasonProviderLate;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'Booked by mistake'**
  String get bookingsReasonByMistake;

  /// Provider cancel reason
  ///
  /// In en, this message translates to:
  /// **'Provider had an emergency'**
  String get bookingsReasonEmergency;

  /// Provider cancel reason
  ///
  /// In en, this message translates to:
  /// **'Could not reach you'**
  String get bookingsReasonUnreachable;

  /// Provider cancel reason
  ///
  /// In en, this message translates to:
  /// **'Location felt unsafe'**
  String get bookingsReasonUnsafe;

  /// Decline reason
  ///
  /// In en, this message translates to:
  /// **'Provider was busy'**
  String get bookingsReasonBusy;

  /// Decline reason
  ///
  /// In en, this message translates to:
  /// **'Too far away'**
  String get bookingsReasonTooFar;

  /// Decline reason
  ///
  /// In en, this message translates to:
  /// **'Not a service they offer'**
  String get bookingsReasonNotMyService;

  /// Cancel or decline reason
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get bookingsReasonOther;

  /// C64 title
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get bookingsReceiptTitle;

  /// C64 number
  ///
  /// In en, this message translates to:
  /// **'Receipt {number}'**
  String bookingsReceiptNumber(String number);

  /// C64 completion time
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String bookingsReceiptCompleted(String date);

  /// C64 field
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get bookingsReceiptService;

  /// C64 field
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get bookingsReceiptProvider;

  /// C64 field
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get bookingsReceiptCustomer;

  /// C64 field
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get bookingsReceiptArea;

  /// C64 footer
  ///
  /// In en, this message translates to:
  /// **'Thank you for choosing PAO.'**
  String get bookingsReceiptThanks;

  /// C64 button
  ///
  /// In en, this message translates to:
  /// **'Share as PDF'**
  String get bookingsReceiptShare;

  /// C64 share error
  ///
  /// In en, this message translates to:
  /// **'Could not share the receipt. Please try again.'**
  String get bookingsReceiptShareFailed;

  /// C20 title
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportTitle;

  /// C20 intro
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong. Our support team reads every report.'**
  String get reportIntro;

  /// C20 reason heading
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get reportReason;

  /// Missing reason
  ///
  /// In en, this message translates to:
  /// **'Choose a reason.'**
  String get reportNeedReason;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Provider did not come'**
  String get reportReasonNoShow;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Provider was late'**
  String get reportReasonLate;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Poor quality work'**
  String get reportReasonPoorQuality;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Charged more than the price'**
  String get reportReasonOvercharge;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Something was damaged'**
  String get reportReasonDamage;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Rude or unprofessional'**
  String get reportReasonBehaviour;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'I felt unsafe'**
  String get reportReasonSafety;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Payment problem'**
  String get reportReasonPayment;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get reportDescription;

  /// Description hint
  ///
  /// In en, this message translates to:
  /// **'What happened, and when?'**
  String get reportDescriptionHint;

  /// Bad description
  ///
  /// In en, this message translates to:
  /// **'Write 10 to 1000 characters.'**
  String get reportDescriptionInvalid;

  /// Photo heading
  ///
  /// In en, this message translates to:
  /// **'Photos ({count} of {max})'**
  String reportPhotos(String count, String max);

  /// Camera button
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get reportTakePhoto;

  /// Gallery button
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get reportChoosePhoto;

  /// Remove photo tooltip
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get reportRemovePhoto;

  /// C20 button
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSubmit;

  /// C56 heading
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSent;

  /// C56 body
  ///
  /// In en, this message translates to:
  /// **'Your ticket number is {ticket}. Our team will review it and contact you.'**
  String reportTicket(String ticket);

  /// C56 button
  ///
  /// In en, this message translates to:
  /// **'Back to booking'**
  String get reportBackToBooking;

  /// C21 action
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifReadAll;

  /// C59 title
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifEmpty;

  /// C59 body
  ///
  /// In en, this message translates to:
  /// **'Updates about your bookings will appear here.'**
  String get notifEmptyBody;

  /// Unread marker label
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifUnread;

  /// C22 row and C23 title
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get accountEditProfile;

  /// C22 row and C24 title
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get accountAddresses;

  /// C22 row and C26 title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// C22 row and C27 title
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get accountHelp;

  /// C22 row and C28 title
  ///
  /// In en, this message translates to:
  /// **'Terms & privacy'**
  String get accountLegal;

  /// C22 row and C29 title
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// C22 row and C30 button
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get accountLogOut;

  /// C30 title
  ///
  /// In en, this message translates to:
  /// **'Log out of PAO?'**
  String get accountLogOutTitle;

  /// C30 body
  ///
  /// In en, this message translates to:
  /// **'You will need your phone number and a code to sign in again.'**
  String get accountLogOutBody;

  /// C23 photo button
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get accountChangePhoto;

  /// C23 saved message
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get accountProfileSaved;

  /// C24 empty title
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get accountAddressesEmpty;

  /// C24 empty body
  ///
  /// In en, this message translates to:
  /// **'Save your home or office to book faster.'**
  String get accountAddressesEmptyBody;

  /// C24 button
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get accountAddressAdd;

  /// C24 limit note
  ///
  /// In en, this message translates to:
  /// **'You can save up to {max} addresses.'**
  String accountAddressLimit(String max);

  /// Default address badge
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get accountAddressDefault;

  /// Address action
  ///
  /// In en, this message translates to:
  /// **'Make default'**
  String get accountAddressMakeDefault;

  /// Address action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get accountAddressEdit;

  /// Address action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountAddressDelete;

  /// Delete confirm title
  ///
  /// In en, this message translates to:
  /// **'Delete this address?'**
  String get accountAddressDeleteTitle;

  /// Delete confirm body
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your saved addresses.'**
  String get accountAddressDeleteBody;

  /// Address menu tooltip
  ///
  /// In en, this message translates to:
  /// **'Address actions'**
  String get accountAddressActions;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get accountAddressHome;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get accountAddressOffice;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountAddressOther;

  /// C26 body
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app, notifications and SMS.'**
  String get accountLanguageBody;

  /// C26 sync error
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone but not on your profile yet: {reason}'**
  String accountLanguageNotSynced(String reason);

  /// C27 heading
  ///
  /// In en, this message translates to:
  /// **'Answers to common questions'**
  String get accountHelpIntro;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'How do I book a service?'**
  String get accountHelpBookQ;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'Pick a service, choose a nearby verified provider, then confirm the time and address. The provider has a few minutes to accept.'**
  String get accountHelpBookA;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'How do I pay?'**
  String get accountHelpPayQ;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'Pay the provider in cash when the job is done. You pay the price shown when booking, plus any extras you approve.'**
  String get accountHelpPayA;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'What is the start code?'**
  String get accountHelpCodeQ;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'When the provider arrives, tell them the 4-digit code from the app. The job starts only after they enter it, so you know the right person is at your door.'**
  String get accountHelpCodeA;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'Can I cancel a booking?'**
  String get accountHelpCancelQ;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'Yes, until the job starts. Open the booking, tap Cancel and pick a reason.'**
  String get accountHelpCancelA;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. What now?'**
  String get accountHelpProblemQ;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'Open the booking and tap Report a problem. Our support team reviews every report.'**
  String get accountHelpProblemA;

  /// C27 contact heading
  ///
  /// In en, this message translates to:
  /// **'Still need help? Our support team is here for you.'**
  String get accountHelpStillStuck;

  /// C27 call button
  ///
  /// In en, this message translates to:
  /// **'Call support'**
  String get accountHelpCall;

  /// C27 email button
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get accountHelpEmail;

  /// Support email subject
  ///
  /// In en, this message translates to:
  /// **'PAO support request'**
  String get accountHelpEmailSubject;

  /// C28 heading
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get accountLegalTermsHeading;

  /// C28 terms
  ///
  /// In en, this message translates to:
  /// **'PAO connects you with independent, verified service providers. Prices are fixed and shown before you book; extra work needs your approval in the app. You pay the provider in cash when the job is done. Please be at the address on time, treat providers with respect and cancel early if your plans change. Accounts that misuse PAO may be suspended.'**
  String get accountLegalTermsBody;

  /// C28 heading
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get accountLegalPrivacyHeading;

  /// C28 privacy
  ///
  /// In en, this message translates to:
  /// **'We keep your name, phone number, photo and saved addresses to run your bookings. A provider sees your exact address and phone number only after accepting your booking. We use your location only when you ask us to find it. We never sell your data.'**
  String get accountLegalPrivacyBody;

  /// C28 heading
  ///
  /// In en, this message translates to:
  /// **'Your choices'**
  String get accountLegalChoicesHeading;

  /// C28 choices
  ///
  /// In en, this message translates to:
  /// **'You can change your profile and language at any time, and delete your account from the Account tab. Deleting removes your personal details; records of past bookings are kept without them.'**
  String get accountLegalChoicesBody;

  /// C29 heading
  ///
  /// In en, this message translates to:
  /// **'Before you go'**
  String get accountDeleteHeading;

  /// C29 body
  ///
  /// In en, this message translates to:
  /// **'Deleting your account removes your name, photo, phone number and saved addresses, and signs you out on every device. This cannot be undone.'**
  String get accountDeleteBody;

  /// C29 note
  ///
  /// In en, this message translates to:
  /// **'Records of past bookings are kept without your personal details.'**
  String get accountDeleteRecords;

  /// C29 button
  ///
  /// In en, this message translates to:
  /// **'Send confirmation code'**
  String get accountDeleteSendCode;

  /// C61 heading
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get accountDeleteCodeTitle;

  /// C61 body
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}. Enter it to delete your account.'**
  String accountDeleteCodeBody(String phone);

  /// C61 resend
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get accountDeleteResend;

  /// C61 button
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get accountDeleteConfirm;

  /// C62 title
  ///
  /// In en, this message translates to:
  /// **'Your account is deleted'**
  String get accountDeletedTitle;

  /// C62 body
  ///
  /// In en, this message translates to:
  /// **'Thank you for using PAO. You can create a new account with your phone number at any time.'**
  String get accountDeletedBody;

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

  /// C34 heading
  ///
  /// In en, this message translates to:
  /// **'Find services near you'**
  String get locPermTitle;

  /// C34 explanation
  ///
  /// In en, this message translates to:
  /// **'PAO reads your location once to set your address and show providers nearby. We never track you in the background.'**
  String get locPermBody;

  /// C34 primary button
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get locPermAllow;

  /// C34 secondary button
  ///
  /// In en, this message translates to:
  /// **'Enter address manually'**
  String get locPermManual;

  /// C06 title
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get locTitleSet;

  /// C25 title when adding
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get locTitleNew;

  /// C25 title when editing
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get locTitleEdit;

  /// Button that reads the GPS position
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get locUseCurrent;

  /// GPS off or refused
  ///
  /// In en, this message translates to:
  /// **'We could not find your location. Search for your address or move the pin.'**
  String get locLocateFailed;

  /// Hint under the map
  ///
  /// In en, this message translates to:
  /// **'Drag the map to move the pin'**
  String get locDragHint;

  /// Map label before a place name is known
  ///
  /// In en, this message translates to:
  /// **'Your pin'**
  String get locPinHere;

  /// Address search field label
  ///
  /// In en, this message translates to:
  /// **'Search for an address'**
  String get locSearch;

  /// Address search placeholder
  ///
  /// In en, this message translates to:
  /// **'Road, area or landmark'**
  String get locSearchHint;

  /// Address label chooser heading
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get locLabel;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get locLabelHome;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get locLabelOffice;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get locLabelOther;

  /// Address line 1 label
  ///
  /// In en, this message translates to:
  /// **'House and road'**
  String get locLine1;

  /// Address line 1 example
  ///
  /// In en, this message translates to:
  /// **'House 12, Road 5, Block C'**
  String get locLine1Hint;

  /// Address line 1 too short or long
  ///
  /// In en, this message translates to:
  /// **'Enter 3 to 200 characters.'**
  String get locLine1Invalid;

  /// Address line 2 label
  ///
  /// In en, this message translates to:
  /// **'Floor, flat or landmark (optional)'**
  String get locLine2;

  /// Address area label
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get locArea;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get locSave;

  /// The pin is inside a launch area
  ///
  /// In en, this message translates to:
  /// **'PAO works in {area}'**
  String locCovered(String area);

  /// C35 heading
  ///
  /// In en, this message translates to:
  /// **'We are not here yet'**
  String get locNotCoveredTitle;

  /// C35 note on the address form
  ///
  /// In en, this message translates to:
  /// **'PAO is not available at this location yet. You can still save it and book once we arrive.'**
  String get locNotCoveredBody;

  /// C07 address header caption
  ///
  /// In en, this message translates to:
  /// **'Your address'**
  String get homeAddressTitle;

  /// C07 header without an address
  ///
  /// In en, this message translates to:
  /// **'Set your address'**
  String get homeNoAddress;

  /// C07 without an address
  ///
  /// In en, this message translates to:
  /// **'Add your address to see services near you.'**
  String get homeNoAddressBody;

  /// C07 search bar
  ///
  /// In en, this message translates to:
  /// **'Search for a service'**
  String get homeSearchHint;

  /// C07 category grid heading
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get homeCategories;

  /// C07 link and C37 title
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get homeAllServices;

  /// Empty catalog
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get homeNoServices;

  /// Address switch sheet title
  ///
  /// In en, this message translates to:
  /// **'Choose address'**
  String get homeAddressSheet;

  /// Address sheet action
  ///
  /// In en, this message translates to:
  /// **'Add a new address'**
  String get homeAddAddress;

  /// C35 on home
  ///
  /// In en, this message translates to:
  /// **'PAO is not available at this address yet. Choose another address to see services.'**
  String get homeNotCoveredBody;

  /// C35 button
  ///
  /// In en, this message translates to:
  /// **'Change address'**
  String get homeChangeAddress;

  /// Active booking banner action
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get homeActiveOpen;

  /// Active booking status
  ///
  /// In en, this message translates to:
  /// **'Waiting for the provider to accept'**
  String get homeStatusRequested;

  /// Active booking status
  ///
  /// In en, this message translates to:
  /// **'The provider accepted'**
  String get homeStatusAccepted;

  /// Active booking status
  ///
  /// In en, this message translates to:
  /// **'The provider is on the way'**
  String get homeStatusOnTheWay;

  /// Active booking status
  ///
  /// In en, this message translates to:
  /// **'The provider has arrived'**
  String get homeStatusArrived;

  /// Active booking status
  ///
  /// In en, this message translates to:
  /// **'The job is in progress'**
  String get homeStatusInProgress;

  /// C08 field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search services, e.g. fan repair'**
  String get searchHint;

  /// C08 before typing
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get searchPrompt;

  /// C08 services heading
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get searchServices;

  /// C08 sub-services heading
  ///
  /// In en, this message translates to:
  /// **'Specific jobs'**
  String get searchSubServices;

  /// C38 heading
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(String query);

  /// C38 explanation
  ///
  /// In en, this message translates to:
  /// **'Check the spelling or try another word. You can also browse all services.'**
  String get searchNoResultsBody;

  /// Price unit
  ///
  /// In en, this message translates to:
  /// **'per job'**
  String get svcPerJob;

  /// Price unit
  ///
  /// In en, this message translates to:
  /// **'per unit'**
  String get svcPerUnit;

  /// Price unit
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get svcPerHour;

  /// Price unit
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get svcPerDay;

  /// Inclusions heading
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get svcIncluded;

  /// Exclusions heading
  ///
  /// In en, this message translates to:
  /// **'Not included'**
  String get svcExcluded;

  /// Price total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get svcTotal;

  /// Nothing selected yet
  ///
  /// In en, this message translates to:
  /// **'Choose at least one item to continue.'**
  String get svcChooseHint;

  /// C43 note
  ///
  /// In en, this message translates to:
  /// **'Only women providers do this service.'**
  String get svcWomenOnly;

  /// C09 continue button
  ///
  /// In en, this message translates to:
  /// **'See providers'**
  String get svcSeeProviders;

  /// C09 price note
  ///
  /// In en, this message translates to:
  /// **'Prices are fixed by PAO. Pay in cash after the job.'**
  String get svcFixedPrice;

  /// Service without sub-services
  ///
  /// In en, this message translates to:
  /// **'Nothing can be booked for this service yet.'**
  String get svcNoItems;

  /// C44 start heading
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get svcHireStart;

  /// C44 date button
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get svcHireDate;

  /// C44 time button
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get svcHireTime;

  /// C44 duty heading
  ///
  /// In en, this message translates to:
  /// **'Duty'**
  String get svcHireDuty;

  /// C44 start in the past
  ///
  /// In en, this message translates to:
  /// **'Choose a start time in the future.'**
  String get svcHireStartPast;

  /// C44 start missing
  ///
  /// In en, this message translates to:
  /// **'Choose when the driver should start.'**
  String get svcHireNeedStart;

  /// Duty length; n is the count in local digits
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} hour} other{{n} hours}}'**
  String svcHours(int count, String n);

  /// Duty length; n is the count in local digits
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} day} other{{n} days}}'**
  String svcDays(int count, String n);

  /// C10 title
  ///
  /// In en, this message translates to:
  /// **'Providers near you'**
  String get provTitle;

  /// C40 button and sheet title
  ///
  /// In en, this message translates to:
  /// **'Sort & filter'**
  String get provSortFilter;

  /// C40 sort heading
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get provSort;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get provSortDistance;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get provSortRating;

  /// C40 filter heading
  ///
  /// In en, this message translates to:
  /// **'Show only'**
  String get provFilter;

  /// Filter option
  ///
  /// In en, this message translates to:
  /// **'4 stars and above'**
  String get provFilterTopRated;

  /// Filter option
  ///
  /// In en, this message translates to:
  /// **'PAO Verified Pro'**
  String get provFilterPro;

  /// C40 apply button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get provApply;

  /// C39 heading
  ///
  /// In en, this message translates to:
  /// **'No providers nearby right now'**
  String get provEmptyTitle;

  /// C39 explanation
  ///
  /// In en, this message translates to:
  /// **'Providers come online throughout the day. Try again in a few minutes or change the filters.'**
  String get provEmptyBody;

  /// C10 without an address
  ///
  /// In en, this message translates to:
  /// **'Add your address first'**
  String get provNoAddressTitle;

  /// C10 without an address
  ///
  /// In en, this message translates to:
  /// **'We need your address to find providers near you.'**
  String get provNoAddressBody;

  /// C10 opened without a selection
  ///
  /// In en, this message translates to:
  /// **'Choose what you need on the service page first.'**
  String get provNoDraft;

  /// Back to the service page
  ///
  /// In en, this message translates to:
  /// **'Choose items'**
  String get provChooseItems;

  /// C10 price summary
  ///
  /// In en, this message translates to:
  /// **'Price for your selection'**
  String get provPriceFor;

  /// Completed jobs; n is the count in local digits
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} job done} other{{n} jobs done}}'**
  String provJobs(int count, String n);

  /// Distance in kilometres
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String provKmAway(String km);

  /// Distance in metres
  ///
  /// In en, this message translates to:
  /// **'{m} m away'**
  String provMAway(String m);

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get provBadgeNone;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get provBadgeVerified;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'PAO Verified Pro'**
  String get provBadgeVerifiedPro;

  /// C41 link
  ///
  /// In en, this message translates to:
  /// **'What do badges mean?'**
  String get provBadgeWhat;

  /// C41 title
  ///
  /// In en, this message translates to:
  /// **'About badges'**
  String get provBadgeSheet;

  /// C41 Level 1
  ///
  /// In en, this message translates to:
  /// **'A PAO verifier checked their NID, selfie, police clearance, address and emergency contact.'**
  String get provBadgeVerifiedBody;

  /// C41 Level 2
  ///
  /// In en, this message translates to:
  /// **'Verified, and PAO also checked their work in person with a skill test or a supervised job. Pros are listed higher.'**
  String get provBadgeProBody;

  /// Experience; n is the count in local digits
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} year of experience} other{{n} years of experience}}'**
  String provExperience(int count, String n);

  /// Join date
  ///
  /// In en, this message translates to:
  /// **'On PAO since {date}'**
  String provMemberSince(String date);

  /// C11 services heading
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get provServices;

  /// C11 rating heading
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get provRatings;

  /// Number of ratings; n is the count in local digits
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No ratings yet} =1{{n} rating} other{{n} ratings}}'**
  String provRatingCount(int count, String n);

  /// C11 reviews heading
  ///
  /// In en, this message translates to:
  /// **'Recent reviews'**
  String get provReviews;

  /// C11 link and C42 title
  ///
  /// In en, this message translates to:
  /// **'All reviews'**
  String get provAllReviews;

  /// No reviews
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get provNoReviews;

  /// No reviews explanation
  ///
  /// In en, this message translates to:
  /// **'Reviews appear here after completed jobs.'**
  String get provNoReviewsBody;

  /// C11 book button
  ///
  /// In en, this message translates to:
  /// **'Book {name}'**
  String provBook(String name);

  /// C11 bio heading
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get provAbout;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get provTagOnTime;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get provTagProfessional;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Quality work'**
  String get provTagQualityWork;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get provTagClean;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get provTagFriendly;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Fair price'**
  String get provTagFairPrice;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get provTagLate;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Rude'**
  String get provTagRude;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Poor quality'**
  String get provTagPoorQuality;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Messy'**
  String get provTagMessy;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get provTagPolite;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Clear instructions'**
  String get provTagClearInstructions;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Paid promptly'**
  String get provTagPaidPromptly;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Safe place'**
  String get provTagSafePlace;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Unclear instructions'**
  String get provTagUnclearInstructions;

  /// Review tag
  ///
  /// In en, this message translates to:
  /// **'Unsafe place'**
  String get provTagUnsafePlace;
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
