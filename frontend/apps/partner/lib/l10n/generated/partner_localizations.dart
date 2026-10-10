import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'partner_localizations_bn.dart';
import 'partner_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PartnerL10n
/// returned by `PartnerL10n.of(context)`.
///
/// Applications need to include `PartnerL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/partner_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PartnerL10n.localizationsDelegates,
///   supportedLocales: PartnerL10n.supportedLocales,
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
/// be consistent with the languages listed in the PartnerL10n.supportedLocales
/// property.
abstract class PartnerL10n {
  PartnerL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PartnerL10n of(BuildContext context) {
    return Localizations.of<PartnerL10n>(context, PartnerL10n)!;
  }

  static const LocalizationsDelegate<PartnerL10n> delegate =
      _PartnerL10nDelegate();

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

  /// App name.
  ///
  /// In en, this message translates to:
  /// **'PAO Partner'**
  String get partnerTitle;

  /// M03 title.
  ///
  /// In en, this message translates to:
  /// **'What is your phone number?'**
  String get authPhoneTitle;

  /// M03 body.
  ///
  /// In en, this message translates to:
  /// **'We will text you a code to sign in.'**
  String get authPhoneBody;

  /// Phone field label.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authPhoneLabel;

  /// Phone validation.
  ///
  /// In en, this message translates to:
  /// **'Enter an 11-digit Bangladeshi mobile number.'**
  String get authPhoneInvalid;

  /// M03 button.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// M04 title.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authOtpTitle;

  /// M04 body.
  ///
  /// In en, this message translates to:
  /// **'We sent it to {phone}.'**
  String authOtpSentTo(String phone);

  /// Resend countdown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String authResendIn(int seconds);

  /// Resend button.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResend;

  /// M15 switch title while online.
  ///
  /// In en, this message translates to:
  /// **'You are online'**
  String get homeOnline;

  /// M15 switch title while offline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get homeOffline;

  /// M15 switch subtitle while online.
  ///
  /// In en, this message translates to:
  /// **'Customers nearby can send you requests.'**
  String get homeOnlineBody;

  /// M15 switch subtitle while offline.
  ///
  /// In en, this message translates to:
  /// **'Go online to receive requests.'**
  String get homeOfflineBody;

  /// Shown when going online fails because location is off (PRD §11).
  ///
  /// In en, this message translates to:
  /// **'Turn on location to go online. It is shared only while you are online.'**
  String get homeLocationOff;

  /// M15b title.
  ///
  /// In en, this message translates to:
  /// **'Requests paused'**
  String get homePausedTitle;

  /// M15b body.
  ///
  /// In en, this message translates to:
  /// **'A document has expired. Renew it to receive requests again.'**
  String get homePausedBody;

  /// M15b button to the documents screen.
  ///
  /// In en, this message translates to:
  /// **'Renew document'**
  String get homeRenew;

  /// Expiry banner on M15 (P-11).
  ///
  /// In en, this message translates to:
  /// **'A document expires on {date}. Renew it to keep receiving requests.'**
  String homeExpiring(String date);

  /// Earnings card title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s earnings'**
  String get homeToday;

  /// Completed jobs today.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job today} other{{count} jobs today}}'**
  String homeJobsToday(int count);

  /// Active job card heading.
  ///
  /// In en, this message translates to:
  /// **'Active job'**
  String get homeActiveJob;

  /// Pending requests heading.
  ///
  /// In en, this message translates to:
  /// **'New requests'**
  String get homeRequests;

  /// Empty requests title.
  ///
  /// In en, this message translates to:
  /// **'No requests right now'**
  String get homeNoRequests;

  /// Empty requests body.
  ///
  /// In en, this message translates to:
  /// **'Stay online to receive requests nearby.'**
  String get homeNoRequestsBody;

  /// M16 title.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get reqTitle;

  /// M16 countdown, time as m:ss.
  ///
  /// In en, this message translates to:
  /// **'{time} left to answer'**
  String reqTimeLeft(String time);

  /// ASAP timing.
  ///
  /// In en, this message translates to:
  /// **'As soon as possible'**
  String get reqAsap;

  /// Scheduled timing.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String reqScheduled(String time);

  /// Distance to the customer area.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String reqDistance(String km);

  /// Booking note label.
  ///
  /// In en, this message translates to:
  /// **'Customer note'**
  String get reqNote;

  /// Accept button.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get reqAccept;

  /// Reject button.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reqReject;

  /// Reject sheet title.
  ///
  /// In en, this message translates to:
  /// **'Why are you rejecting?'**
  String get reqRejectTitle;

  /// Reject reason busy.
  ///
  /// In en, this message translates to:
  /// **'I am busy'**
  String get reqReasonBusy;

  /// Reject reason too_far.
  ///
  /// In en, this message translates to:
  /// **'Too far away'**
  String get reqReasonTooFar;

  /// Reject reason not_my_service.
  ///
  /// In en, this message translates to:
  /// **'Not my service'**
  String get reqReasonNotMyService;

  /// Reject reason other.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get reqReasonOther;

  /// Expired request title.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer open'**
  String get reqExpiredTitle;

  /// Expired request body.
  ///
  /// In en, this message translates to:
  /// **'The time to answer passed or it was already answered.'**
  String get reqExpiredBody;

  /// M17 title.
  ///
  /// In en, this message translates to:
  /// **'Active job'**
  String get jobLiveTitle;

  /// Status requested.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your answer'**
  String get jobStatusRequested;

  /// Status accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get jobStepAccepted;

  /// Status on_the_way.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get jobStepOnTheWay;

  /// Status arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get jobStepArrived;

  /// Status in_progress.
  ///
  /// In en, this message translates to:
  /// **'Job started'**
  String get jobStepStarted;

  /// Status completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobStepCompleted;

  /// Status cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get jobStatusCancelled;

  /// Status rejected or timed out.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get jobStatusClosed;

  /// Customer fallback name.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get jobCustomer;

  /// Opens Google Maps (P-07).
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get jobActionNavigate;

  /// Calls the customer.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get jobActionCall;

  /// Marks on the way.
  ///
  /// In en, this message translates to:
  /// **'I\'m on the way'**
  String get jobActionOnTheWay;

  /// Marks arrived.
  ///
  /// In en, this message translates to:
  /// **'I\'ve arrived'**
  String get jobActionArrived;

  /// Opens M18.
  ///
  /// In en, this message translates to:
  /// **'Enter start code'**
  String get jobActionStart;

  /// Opens M19.
  ///
  /// In en, this message translates to:
  /// **'Add extra items'**
  String get jobActionExtras;

  /// Opens M20 and confirms there.
  ///
  /// In en, this message translates to:
  /// **'Complete job'**
  String get jobActionComplete;

  /// Opens M21.
  ///
  /// In en, this message translates to:
  /// **'Rate customer'**
  String get jobActionRate;

  /// Opens M16 for a job still requested.
  ///
  /// In en, this message translates to:
  /// **'Open request'**
  String get jobActionOpenRequest;

  /// Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get jobActionCancel;

  /// Returns to M15.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get jobBackHome;

  /// Returns to M17.
  ///
  /// In en, this message translates to:
  /// **'Back to job'**
  String get jobBackToJob;

  /// Bill total label.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get jobTotal;

  /// Booked line quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity {count}'**
  String jobQuantity(int count);

  /// Extra line quantity.
  ///
  /// In en, this message translates to:
  /// **'Extra · quantity {count}'**
  String jobExtraQuantity(int count);

  /// Cancel sheet title.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get jobCancelTitle;

  /// Cancel consequence (PRD §5).
  ///
  /// In en, this message translates to:
  /// **'Cancelling after accepting lowers your ranking.'**
  String get jobCancelWarning;

  /// Cancel reason emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get jobCancelEmergency;

  /// Cancel reason customer_unreachable.
  ///
  /// In en, this message translates to:
  /// **'Customer not reachable'**
  String get jobCancelUnreachable;

  /// Cancel reason unsafe_location.
  ///
  /// In en, this message translates to:
  /// **'Unsafe location'**
  String get jobCancelUnsafe;

  /// Cancel reason other.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get jobCancelOther;

  /// Reason note field.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get jobNoteLabel;

  /// Cancelled job title.
  ///
  /// In en, this message translates to:
  /// **'This job was cancelled'**
  String get jobCancelledTitle;

  /// Cancelled by the customer.
  ///
  /// In en, this message translates to:
  /// **'The customer cancelled this job.'**
  String get jobCancelledByCustomer;

  /// Cancelled by someone else.
  ///
  /// In en, this message translates to:
  /// **'It can no longer be worked on.'**
  String get jobCancelledOther;

  /// Rejected or timed-out job title.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer active'**
  String get jobClosedTitle;

  /// M18 title.
  ///
  /// In en, this message translates to:
  /// **'Enter start code'**
  String get jobStartTitle;

  /// M18 body.
  ///
  /// In en, this message translates to:
  /// **'Ask the customer for the 4-digit code in their app.'**
  String get jobStartBody;

  /// M19 title.
  ///
  /// In en, this message translates to:
  /// **'Add extra items'**
  String get jobExtrasTitle;

  /// M19 empty state.
  ///
  /// In en, this message translates to:
  /// **'There are no extra items for this service.'**
  String get jobExtrasEmpty;

  /// M19 submit with the added total.
  ///
  /// In en, this message translates to:
  /// **'Send to customer · {amount}'**
  String jobExtrasSend(String amount);

  /// M19 pending title.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer'**
  String get jobExtrasWaitingTitle;

  /// Pending extras note.
  ///
  /// In en, this message translates to:
  /// **'The customer is asked to approve {amount} of extra items.'**
  String jobExtrasWaiting(String amount);

  /// Last proposal approved.
  ///
  /// In en, this message translates to:
  /// **'The customer approved the last extra items.'**
  String get jobExtrasApproved;

  /// Last proposal declined.
  ///
  /// In en, this message translates to:
  /// **'The customer declined the last extra items.'**
  String get jobExtrasDeclined;

  /// M20 title.
  ///
  /// In en, this message translates to:
  /// **'Complete job'**
  String get jobCompleteTitle;

  /// M20 cash confirmation (D4).
  ///
  /// In en, this message translates to:
  /// **'I received {amount} in cash'**
  String jobCashReceived(String amount);

  /// M21 title.
  ///
  /// In en, this message translates to:
  /// **'Rate the customer'**
  String get jobRateTitle;

  /// M21 question.
  ///
  /// In en, this message translates to:
  /// **'How was this customer?'**
  String get jobRateQuestion;

  /// Star input label.
  ///
  /// In en, this message translates to:
  /// **'{stars} out of 5 stars'**
  String jobRateStars(int stars);

  /// Comment field.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get jobRateComment;

  /// M21 submit.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get jobRateSubmit;

  /// M21 skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get jobRateSkip;

  /// Tag polite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get jobTagPolite;

  /// Tag clear_instructions.
  ///
  /// In en, this message translates to:
  /// **'Clear instructions'**
  String get jobTagClearInstructions;

  /// Tag paid_promptly.
  ///
  /// In en, this message translates to:
  /// **'Paid promptly'**
  String get jobTagPaidPromptly;

  /// Tag safe_place.
  ///
  /// In en, this message translates to:
  /// **'Safe place'**
  String get jobTagSafePlace;

  /// Tag rude.
  ///
  /// In en, this message translates to:
  /// **'Rude'**
  String get jobTagRude;

  /// Tag unclear_instructions.
  ///
  /// In en, this message translates to:
  /// **'Unclear instructions'**
  String get jobTagUnclearInstructions;

  /// Tag unsafe_place.
  ///
  /// In en, this message translates to:
  /// **'Unsafe place'**
  String get jobTagUnsafePlace;

  /// Inbox action.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifReadAll;

  /// Inbox empty title.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifEmpty;

  /// Inbox empty body.
  ///
  /// In en, this message translates to:
  /// **'Updates about requests, jobs and documents appear here.'**
  String get notifEmptyBody;
}

class _PartnerL10nDelegate extends LocalizationsDelegate<PartnerL10n> {
  const _PartnerL10nDelegate();

  @override
  Future<PartnerL10n> load(Locale locale) {
    return SynchronousFuture<PartnerL10n>(lookupPartnerL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_PartnerL10nDelegate old) => false;
}

PartnerL10n lookupPartnerL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return PartnerL10nBn();
    case 'en':
      return PartnerL10nEn();
  }

  throw FlutterError(
    'PartnerL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
