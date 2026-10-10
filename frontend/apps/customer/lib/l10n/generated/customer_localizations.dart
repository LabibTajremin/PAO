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
