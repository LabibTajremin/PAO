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

  /// A05 heading
  ///
  /// In en, this message translates to:
  /// **'Verification queue'**
  String get verifyQueueTitle;

  /// A05 empty state
  ///
  /// In en, this message translates to:
  /// **'No providers are waiting for review.'**
  String get verifyQueueEmpty;

  /// A05 filter label
  ///
  /// In en, this message translates to:
  /// **'Pending item'**
  String get verifyFilterItem;

  /// A05 filter: no item filter
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get verifyFilterAll;

  /// A05 column
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get verifyColProvider;

  /// A05 column
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get verifyColServices;

  /// A05 column: pending items
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get verifyColPending;

  /// A05 column: age of the submission
  ///
  /// In en, this message translates to:
  /// **'Waiting for'**
  String get verifyColWaiting;

  /// A05 wait in hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String verifyAgeHours(int count);

  /// A05 wait in days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String verifyAgeDays(int count);

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get verifyItemNid;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Live selfie'**
  String get verifyItemSelfie;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Police clearance'**
  String get verifyItemPolice;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get verifyItemAddress;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get verifyItemEmergency;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Skill proof'**
  String get verifyItemSkill;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get verifyItemServiceArea;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Code of conduct'**
  String get verifyItemConduct;

  /// Item status
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get verifyStatusMissing;

  /// Item status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get verifyStatusPending;

  /// Item status
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get verifyStatusApproved;

  /// Item status
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get verifyStatusRejected;

  /// Item status
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get verifyStatusExpired;

  /// Item is required for Level 1
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get verifyRequired;

  /// Item is optional for Level 1
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get verifyOptional;

  /// Verification level
  ///
  /// In en, this message translates to:
  /// **'Level 0 · Registered'**
  String get verifyLevel0;

  /// Verification level
  ///
  /// In en, this message translates to:
  /// **'Level 1 · Verified'**
  String get verifyLevel1;

  /// Verification level
  ///
  /// In en, this message translates to:
  /// **'Level 2 · PAO Verified Pro'**
  String get verifyLevel2;

  /// A06 face check heading
  ///
  /// In en, this message translates to:
  /// **'Face match'**
  String get verifyFaceTitle;

  /// Face check result
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get verifyFaceNotRun;

  /// Face check result
  ///
  /// In en, this message translates to:
  /// **'Face matches'**
  String get verifyFaceMatch;

  /// Face check result
  ///
  /// In en, this message translates to:
  /// **'Face does not match'**
  String get verifyFaceNoMatch;

  /// Face check left to the verifier
  ///
  /// In en, this message translates to:
  /// **'Compare the selfie with the NID photo'**
  String get verifyFaceManual;

  /// Gender
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get verifyGenderFemale;

  /// Gender
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get verifyGenderMale;

  /// Gender
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get verifyGenderOther;

  /// Document kind
  ///
  /// In en, this message translates to:
  /// **'NID front'**
  String get verifyDocNidFront;

  /// Document kind
  ///
  /// In en, this message translates to:
  /// **'NID back'**
  String get verifyDocNidBack;

  /// Submitted value
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get verifyFieldIssueDate;

  /// Submitted value
  ///
  /// In en, this message translates to:
  /// **'Working radius (m)'**
  String get verifyFieldRadius;

  /// Submitted value: number of services
  ///
  /// In en, this message translates to:
  /// **'Services chosen'**
  String get verifyFieldServices;

  /// Submitted value
  ///
  /// In en, this message translates to:
  /// **'Home latitude'**
  String get verifyFieldHomeLat;

  /// Submitted value
  ///
  /// In en, this message translates to:
  /// **'Home longitude'**
  String get verifyFieldHomeLng;

  /// Submitted value: emergency contact
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get verifyFieldName;

  /// Submitted value: emergency contact
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get verifyFieldRelation;

  /// A06 panel heading
  ///
  /// In en, this message translates to:
  /// **'NID and profile'**
  String get verifyProfileTitle;

  /// A06 profile
  ///
  /// In en, this message translates to:
  /// **'NID number'**
  String get verifyNidNumber;

  /// A06 profile
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get verifyFullName;

  /// A06 profile
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get verifyDob;

  /// A06 profile
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get verifyGender;

  /// A06 profile
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get verifyPhone;

  /// A06 profile
  ///
  /// In en, this message translates to:
  /// **'Present address'**
  String get verifyPresentAddress;

  /// A06 profile
  ///
  /// In en, this message translates to:
  /// **'Permanent address'**
  String get verifyPermanentAddress;

  /// A06 profile: empty value
  ///
  /// In en, this message translates to:
  /// **'Not given'**
  String get verifyNotGiven;

  /// Reject reason template
  ///
  /// In en, this message translates to:
  /// **'The photo is blurry. Retake it in good light.'**
  String get verifyReasonBlurry;

  /// Reject reason template
  ///
  /// In en, this message translates to:
  /// **'The name does not match the profile.'**
  String get verifyReasonName;

  /// Reject reason template
  ///
  /// In en, this message translates to:
  /// **'The document has expired.'**
  String get verifyReasonExpired;

  /// Reject reason template
  ///
  /// In en, this message translates to:
  /// **'The selfie does not match the NID photo.'**
  String get verifyReasonFace;

  /// Reject reason template
  ///
  /// In en, this message translates to:
  /// **'Part of the document is cut off.'**
  String get verifyReasonCropped;

  /// Item rejection reason
  ///
  /// In en, this message translates to:
  /// **'Rejected: {reason}'**
  String verifyRejectedBecause(String reason);

  /// Item expiry
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String verifyExpires(String date);

  /// When the item was decided
  ///
  /// In en, this message translates to:
  /// **'Decided {date}'**
  String verifyDecidedAt(String date);

  /// A06 button
  ///
  /// In en, this message translates to:
  /// **'Open documents'**
  String get verifyOpenDocs;

  /// A06: no verification:docs:view
  ///
  /// In en, this message translates to:
  /// **'You may not open documents'**
  String get verifyDocsLocked;

  /// A06 button
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get verifyApprove;

  /// A06 button
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get verifyReject;

  /// A06 reject dialog title
  ///
  /// In en, this message translates to:
  /// **'Reject {item}'**
  String verifyRejectTitle(String item);

  /// A06 heading before the name loads
  ///
  /// In en, this message translates to:
  /// **'Verification review'**
  String get verifyReviewTitle;

  /// A06 back button
  ///
  /// In en, this message translates to:
  /// **'Back to the queue'**
  String get verifyBackToQueue;

  /// A06 button
  ///
  /// In en, this message translates to:
  /// **'Next provider'**
  String get verifyNext;

  /// A06 keyboard hint
  ///
  /// In en, this message translates to:
  /// **'Keys: A approve · R reject · N next · ↑↓ move'**
  String get verifyShortcuts;

  /// A06: no pending items
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for a decision.'**
  String get verifyNoPending;

  /// A06 after a decision
  ///
  /// In en, this message translates to:
  /// **'Saved. The provider is now at {level}.'**
  String verifyDecided(String level);

  /// A06: queue empty on next
  ///
  /// In en, this message translates to:
  /// **'No other providers are waiting.'**
  String get verifyQueueDone;

  /// Document viewer: image failed
  ///
  /// In en, this message translates to:
  /// **'This document could not be shown.'**
  String get verifyViewerBroken;

  /// Document viewer
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get verifyViewerZoomIn;

  /// Document viewer
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get verifyViewerZoomOut;

  /// Document viewer
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get verifyViewerRotateLeft;

  /// Document viewer
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get verifyViewerRotateRight;

  /// A07 heading
  ///
  /// In en, this message translates to:
  /// **'Level 2 sessions'**
  String get level2Title;

  /// A07 button
  ///
  /// In en, this message translates to:
  /// **'Schedule session'**
  String get level2Schedule;

  /// A07 empty state
  ///
  /// In en, this message translates to:
  /// **'No sessions match.'**
  String get level2Empty;

  /// A07 column
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get level2ColWhen;

  /// A07 column
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get level2ColProvider;

  /// A07 column
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get level2ColService;

  /// A07 column
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get level2ColStatus;

  /// Session status
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get level2StatusScheduled;

  /// Session status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get level2StatusCompleted;

  /// Session status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get level2StatusCancelled;

  /// Session result
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get level2ResultPass;

  /// Session result
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get level2ResultFail;

  /// Session result
  ///
  /// In en, this message translates to:
  /// **'Retest'**
  String get level2ResultRetest;

  /// A07 filter
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get level2FilterStatus;

  /// A07 filter: no status filter
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get level2AllStatuses;

  /// A07 filter
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get level2FilterProvider;

  /// A07 filter: no provider filter
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get level2AnyProvider;

  /// Provider search label
  ///
  /// In en, this message translates to:
  /// **'Find a provider'**
  String get level2FindProvider;

  /// Provider search hint
  ///
  /// In en, this message translates to:
  /// **'Name or phone, then Enter'**
  String get level2FindHint;

  /// Provider search: no results
  ///
  /// In en, this message translates to:
  /// **'No provider matches.'**
  String get level2NoProviders;

  /// Schedule dialog title
  ///
  /// In en, this message translates to:
  /// **'Schedule a Level 2 session'**
  String get level2ScheduleTitle;

  /// Schedule dialog: pick another provider
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get level2ChangeProvider;

  /// Schedule dialog
  ///
  /// In en, this message translates to:
  /// **'This provider has not chosen any service.'**
  String get level2NoServices;

  /// Schedule dialog field
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get level2Service;

  /// Schedule dialog field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get level2Date;

  /// Schedule dialog field
  ///
  /// In en, this message translates to:
  /// **'Time (Dhaka)'**
  String get level2Time;

  /// Session location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get level2Location;

  /// Schedule dialog location hint
  ///
  /// In en, this message translates to:
  /// **'PAO office, Gulshan 1'**
  String get level2LocationHint;

  /// Schedule dialog button
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get level2ScheduleSubmit;

  /// Schedule dialog validation
  ///
  /// In en, this message translates to:
  /// **'Choose a provider, a service and a location.'**
  String get level2ScheduleMissing;

  /// Schedule dialog validation
  ///
  /// In en, this message translates to:
  /// **'Choose a time in the future.'**
  String get level2PastTime;

  /// A07 after scheduling
  ///
  /// In en, this message translates to:
  /// **'Session scheduled. The provider will be notified.'**
  String get level2Booked;

  /// API error LEVEL2_NOT_ELIGIBLE, admin wording
  ///
  /// In en, this message translates to:
  /// **'Only Level 1 providers can take a Level 2 session.'**
  String get level2NotEligible;

  /// API error LEVEL2_COOLING_OFF, admin wording
  ///
  /// In en, this message translates to:
  /// **'This provider failed recently and must wait before retrying.'**
  String get level2CoolingOff;

  /// Session drawer title
  ///
  /// In en, this message translates to:
  /// **'Level 2 session'**
  String get level2SessionTitle;

  /// Result form heading
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get level2Checklist;

  /// Checklist item passed
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get level2ItemPassed;

  /// Checklist item not passed
  ///
  /// In en, this message translates to:
  /// **'Not passed'**
  String get level2ItemFailed;

  /// Result form
  ///
  /// In en, this message translates to:
  /// **'Add a checklist item'**
  String get level2AddItem;

  /// Result form heading
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get level2Outcome;

  /// Result form field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get level2Notes;

  /// Result form button
  ///
  /// In en, this message translates to:
  /// **'Record result'**
  String get level2Record;

  /// Result form validation
  ///
  /// In en, this message translates to:
  /// **'Add at least one checklist item.'**
  String get level2NeedChecklist;

  /// Result form validation
  ///
  /// In en, this message translates to:
  /// **'Choose pass, fail or retest.'**
  String get level2NeedResult;
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
