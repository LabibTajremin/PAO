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

  /// M23 title.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsTitle;

  /// M23 tab: jobs not yet finished.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get jobsUpcoming;

  /// M23 tab: finished jobs.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get jobsPast;

  /// M23 empty upcoming tab.
  ///
  /// In en, this message translates to:
  /// **'No upcoming jobs'**
  String get jobsEmptyUpcoming;

  /// M23 empty past tab.
  ///
  /// In en, this message translates to:
  /// **'No past jobs yet'**
  String get jobsEmptyPast;

  /// M23 empty state hint.
  ///
  /// In en, this message translates to:
  /// **'Go online on Home to receive job requests.'**
  String get jobsEmptyBody;

  /// Button that loads the next page of a list.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get jobsLoadMore;

  /// Booking status.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get jobsStatusRequested;

  /// Booking status.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get jobsStatusAccepted;

  /// Booking status.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get jobsStatusOnTheWay;

  /// Booking status.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get jobsStatusArrived;

  /// Booking status.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get jobsStatusInProgress;

  /// Booking status.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobsStatusCompleted;

  /// Booking status.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get jobsStatusRejected;

  /// Booking status: request not answered in time.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get jobsStatusTimedOut;

  /// Booking status.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get jobsStatusCancelled;

  /// M24 title.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobsDetailTitle;

  /// Customer first name on M24.
  ///
  /// In en, this message translates to:
  /// **'Customer: {name}'**
  String jobsCustomer(String name);

  /// Service area on M24.
  ///
  /// In en, this message translates to:
  /// **'Area: {area}'**
  String jobsArea(String area);

  /// M24 section heading.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get jobsItems;

  /// Marks an extra item approved by the customer.
  ///
  /// In en, this message translates to:
  /// **'Added during the job'**
  String get jobsExtra;

  /// Total row.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get jobsTotal;

  /// M24 section heading.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get jobsTimeline;

  /// M24 button to the active job screen.
  ///
  /// In en, this message translates to:
  /// **'Continue job'**
  String get jobsOpenLive;

  /// M24 button for a completed job.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get jobsReceipt;

  /// Receipt sheet title.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get jobsReceiptTitle;

  /// Receipt payment method.
  ///
  /// In en, this message translates to:
  /// **'Paid in cash'**
  String get jobsPaidCash;

  /// M24 button to M25.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get jobsReport;

  /// M25 title.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get jobsReportTitle;

  /// M25 reason heading.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get jobsReportReason;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Customer not available'**
  String get jobsReasonCustomerUnavailable;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Payment problem'**
  String get jobsReasonPayment;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Customer behaviour'**
  String get jobsReasonBehaviour;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get jobsReasonSafety;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get jobsReasonDamage;

  /// Report reason.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get jobsReasonOther;

  /// M25 validation.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason.'**
  String get jobsReportNeedReason;

  /// M25 description label.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get jobsReportDescription;

  /// M25 description hint.
  ///
  /// In en, this message translates to:
  /// **'What happened, and when?'**
  String get jobsReportDescriptionHint;

  /// M25 validation.
  ///
  /// In en, this message translates to:
  /// **'Write between 10 and 1000 characters.'**
  String get jobsReportDescriptionInvalid;

  /// M25 photo heading with the count and the limit.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count} of {max})'**
  String jobsReportPhotos(String count, String max);

  /// M25 camera button.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get jobsReportAddPhoto;

  /// Tooltip on a photo remove button.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get jobsReportRemovePhoto;

  /// M25 submit button.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get jobsReportSubmit;

  /// M25 success title.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get jobsReportSent;

  /// M25 success message.
  ///
  /// In en, this message translates to:
  /// **'Your ticket number is {ticket}. Our team will contact you.'**
  String jobsReportTicket(String ticket);

  /// M25 success button.
  ///
  /// In en, this message translates to:
  /// **'Back to job'**
  String get jobsBackToJob;

  /// M26 title.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnTitle;

  /// M26 period: today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get earnDay;

  /// M26 period: this week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get earnWeek;

  /// M26 period: this month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get earnMonth;

  /// Number of completed jobs; formatted is the count in local digits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{formatted} job} other{{formatted} jobs}}'**
  String earnJobs(int count, String formatted);

  /// M27 heading.
  ///
  /// In en, this message translates to:
  /// **'By job'**
  String get earnByJob;

  /// M27 empty state.
  ///
  /// In en, this message translates to:
  /// **'No earnings yet'**
  String get earnEmptyTitle;

  /// M27 empty state body.
  ///
  /// In en, this message translates to:
  /// **'Completed jobs and what you earned appear here.'**
  String get earnEmptyBody;

  /// M28 title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profTitle;

  /// M28 button.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profChangePhoto;

  /// Verification level with its name.
  ///
  /// In en, this message translates to:
  /// **'Level {level}: {name}'**
  String profLevelOf(String level, String name);

  /// Number of ratings; formatted is the count in local digits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No ratings yet} =1{{formatted} rating} other{{formatted} ratings}}'**
  String profRatingCount(int count, String formatted);

  /// Shown when the bio is empty.
  ///
  /// In en, this message translates to:
  /// **'Tell customers about your work.'**
  String get profNoBio;

  /// M28 button and sheet title.
  ///
  /// In en, this message translates to:
  /// **'Edit bio'**
  String get profEditBio;

  /// Bio field label.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get profBioLabel;

  /// Bio field hint.
  ///
  /// In en, this message translates to:
  /// **'Your skills and experience'**
  String get profBioHint;

  /// Bio validation.
  ///
  /// In en, this message translates to:
  /// **'Keep it under 500 characters.'**
  String get profBioTooLong;

  /// Badge for level 0.
  ///
  /// In en, this message translates to:
  /// **'No badge yet'**
  String get profBadgeNone;

  /// Badge for level 1.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profBadgeVerified;

  /// Badge for level 2.
  ///
  /// In en, this message translates to:
  /// **'PAO Verified Pro'**
  String get profBadgeVerifiedPro;

  /// Level 0 name.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get profLevel0;

  /// Level 1 name.
  ///
  /// In en, this message translates to:
  /// **'Document verified'**
  String get profLevel1;

  /// Level 2 name.
  ///
  /// In en, this message translates to:
  /// **'Skill verified'**
  String get profLevel2;

  /// How level 0 is earned.
  ///
  /// In en, this message translates to:
  /// **'Signed up and verified your phone. You cannot receive bookings yet.'**
  String get profLevel0How;

  /// How level 1 is earned.
  ///
  /// In en, this message translates to:
  /// **'All documents approved by PAO. Customers see \"Verified\" and you receive bookings.'**
  String get profLevel1How;

  /// How level 2 is earned.
  ///
  /// In en, this message translates to:
  /// **'PAO checked your work in person. Customers see \"PAO Verified Pro\" and you rank higher.'**
  String get profLevel2How;

  /// M32 heading.
  ///
  /// In en, this message translates to:
  /// **'Level 2 skill check'**
  String get profLevel2Title;

  /// Level 2 reached.
  ///
  /// In en, this message translates to:
  /// **'You are a PAO Verified Pro.'**
  String get profLevel2Done;

  /// Scheduled level 2 session.
  ///
  /// In en, this message translates to:
  /// **'Your skill check is on {when} at {place}.'**
  String profLevel2Session(String when, String place);

  /// Cooling-off after a failed level 2 session.
  ///
  /// In en, this message translates to:
  /// **'You can try the skill check again after {date}.'**
  String profLevel2Retry(String date);

  /// Level 2 available.
  ///
  /// In en, this message translates to:
  /// **'You can book a skill check. Call PAO support to arrange one.'**
  String get profLevel2Eligible;

  /// Level 2 not available yet.
  ///
  /// In en, this message translates to:
  /// **'Reach Level 1 first; then PAO can check your work in person.'**
  String get profLevel2NotYet;

  /// M29 title and menu row.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get profPublicTitle;

  /// M29 explanation.
  ///
  /// In en, this message translates to:
  /// **'This is how customers see you. They never see your documents or phone number.'**
  String get profPublicHint;

  /// Years of experience; formatted is the count in local digits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{New to the trade} =1{{formatted} year of experience} other{{formatted} years of experience}}'**
  String profExperience(int count, String formatted);

  /// M30 title and menu row.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get profReviewsTitle;

  /// M30 empty state.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get profReviewsEmpty;

  /// M30 empty state body.
  ///
  /// In en, this message translates to:
  /// **'Customers can review you after each completed job.'**
  String get profReviewsEmptyBody;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get profTagOnTime;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get profTagProfessional;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Quality work'**
  String get profTagQualityWork;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get profTagClean;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get profTagFriendly;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Fair price'**
  String get profTagFairPrice;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get profTagLate;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Rude'**
  String get profTagRude;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Poor quality'**
  String get profTagPoorQuality;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Messy'**
  String get profTagMessy;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get profTagPolite;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Clear instructions'**
  String get profTagClearInstructions;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Paid promptly'**
  String get profTagPaidPromptly;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Safe place'**
  String get profTagSafePlace;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Unclear instructions'**
  String get profTagUnclearInstructions;

  /// Review tag.
  ///
  /// In en, this message translates to:
  /// **'Unsafe place'**
  String get profTagUnsafePlace;

  /// M31 title and menu row.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get profDocumentsTitle;

  /// M31 empty state.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get profDocumentsEmpty;

  /// M31 button to the verification screen.
  ///
  /// In en, this message translates to:
  /// **'Update documents'**
  String get profDocumentsUpdate;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get profItemNid;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Live selfie'**
  String get profItemSelfie;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Police clearance'**
  String get profItemPoliceClearance;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profItemAddress;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get profItemEmergencyContact;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Skill proof'**
  String get profItemSkillProof;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Services and area'**
  String get profItemServiceArea;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Code of conduct'**
  String get profItemCodeOfConduct;

  /// Document status.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get profStatusMissing;

  /// Document status.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get profStatusPending;

  /// Document status.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get profStatusApproved;

  /// Document status.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get profStatusRejected;

  /// Document status.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get profStatusExpired;

  /// Document expiry.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String profValidUntil(String date);

  /// Document expiring within 30 days.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}. Renew it soon to keep receiving bookings.'**
  String profExpiresSoon(String date);

  /// Expired document.
  ///
  /// In en, this message translates to:
  /// **'Expired on {date}. Bookings are paused until you renew it.'**
  String profExpired(String date);

  /// M32 title and menu row.
  ///
  /// In en, this message translates to:
  /// **'Badge and level'**
  String get profLevelTitle;

  /// M33 title and menu row.
  ///
  /// In en, this message translates to:
  /// **'Services and area'**
  String get profServicesTitle;

  /// M33 heading.
  ///
  /// In en, this message translates to:
  /// **'Services you offer (up to {max})'**
  String profServicesPick(String max);

  /// M33 field.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get profExperienceLabel;

  /// M33 radius heading.
  ///
  /// In en, this message translates to:
  /// **'How far you travel'**
  String get profRadius;

  /// Working radius option.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String profRadiusKm(String km);

  /// M33 row.
  ///
  /// In en, this message translates to:
  /// **'Home base'**
  String get profHomeBase;

  /// Home base is saved.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get profHomeBaseSet;

  /// Home base is missing.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profHomeBaseMissing;

  /// M33 button.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get profUseLocation;

  /// Location unavailable.
  ///
  /// In en, this message translates to:
  /// **'Turn on location and try again.'**
  String get profLocationOff;

  /// Confirmation after saving.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profSaved;

  /// M34 title and menu row.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profLanguageTitle;

  /// M34 explanation.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app, notifications and messages from PAO.'**
  String get profLanguageBody;

  /// M34 profile update failed.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone, but not on your profile: {reason}'**
  String profLanguageNotSynced(String reason);

  /// M35 title and menu row.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get profHelpTitle;

  /// Help topic.
  ///
  /// In en, this message translates to:
  /// **'How do I get jobs?'**
  String get profHelpJobsQ;

  /// Help answer.
  ///
  /// In en, this message translates to:
  /// **'Go online on Home. Requests from nearby customers appear with a countdown; accept them before it ends.'**
  String get profHelpJobsA;

  /// Help topic.
  ///
  /// In en, this message translates to:
  /// **'What is the start code?'**
  String get profHelpCodeQ;

  /// Help answer.
  ///
  /// In en, this message translates to:
  /// **'When you arrive, ask the customer for their 4-digit code. The job starts only after you enter it.'**
  String get profHelpCodeA;

  /// Help topic.
  ///
  /// In en, this message translates to:
  /// **'How am I paid?'**
  String get profHelpCashQ;

  /// Help answer.
  ///
  /// In en, this message translates to:
  /// **'Customers pay you in cash when the job is done. Confirm the cash in the app to complete the job.'**
  String get profHelpCashA;

  /// Help topic.
  ///
  /// In en, this message translates to:
  /// **'Why did my bookings stop?'**
  String get profHelpDocumentsQ;

  /// Help answer.
  ///
  /// In en, this message translates to:
  /// **'An expired document, such as the police clearance, pauses bookings. Upload a new one in Documents.'**
  String get profHelpDocumentsA;

  /// Help topic.
  ///
  /// In en, this message translates to:
  /// **'How do I become a PAO Verified Pro?'**
  String get profHelpLevelQ;

  /// Help answer.
  ///
  /// In en, this message translates to:
  /// **'After Level 1, PAO can check your work in person. Passing gives you Level 2 and more bookings.'**
  String get profHelpLevelA;

  /// M35 call prompt.
  ///
  /// In en, this message translates to:
  /// **'Still need help? Our team can help you by phone.'**
  String get profHelpStillStuck;

  /// M35 button.
  ///
  /// In en, this message translates to:
  /// **'Call PAO support'**
  String get profHelpCall;

  /// M36 menu row and confirm button.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profLogOut;

  /// M36 sheet title.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profLogOutTitle;

  /// M36 sheet body.
  ///
  /// In en, this message translates to:
  /// **'You will stop receiving job requests on this phone until you sign in again.'**
  String get profLogOutBody;
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
