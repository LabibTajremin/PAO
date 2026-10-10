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

  /// Account status (PRD §6.4)
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get peopleStatusPending;

  /// Account status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get peopleStatusActive;

  /// Account status
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get peopleStatusSuspended;

  /// Account status
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get peopleStatusBanned;

  /// Filter and column: status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get peopleFilterStatus;

  /// Filter option: no filter
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get peopleFilterAny;

  /// Column: name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get peopleName;

  /// Column and fact: phone
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get peoplePhone;

  /// Column and fact: average rating
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get peopleRating;

  /// Fact: no rating
  ///
  /// In en, this message translates to:
  /// **'No rating yet'**
  String get peopleNoRating;

  /// Column and fact: sign-up date
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get peopleJoined;

  /// Account action
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get peopleSuspend;

  /// Account action
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get peopleBan;

  /// Account action
  ///
  /// In en, this message translates to:
  /// **'Reinstate'**
  String get peopleReinstate;

  /// Suspend dialog title
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}?'**
  String peopleSuspendTitle(String name);

  /// Customer ban dialog title
  ///
  /// In en, this message translates to:
  /// **'Ban {name}? Their phone cannot register again.'**
  String peopleBanTitle(String name);

  /// Reinstate dialog title
  ///
  /// In en, this message translates to:
  /// **'Reinstate {name}?'**
  String peopleReinstateTitle(String name);

  /// Reinstate reason template
  ///
  /// In en, this message translates to:
  /// **'Issue resolved after review'**
  String get peopleReasonResolved;

  /// Reinstate reason template
  ///
  /// In en, this message translates to:
  /// **'Appeal accepted'**
  String get peopleReasonAppeal;

  /// Status change succeeded
  ///
  /// In en, this message translates to:
  /// **'Account status updated.'**
  String get peopleStatusChanged;

  /// Detail section
  ///
  /// In en, this message translates to:
  /// **'Recent bookings'**
  String get peopleRecentBookings;

  /// No recent bookings
  ///
  /// In en, this message translates to:
  /// **'No bookings yet.'**
  String get peopleNoBookings;

  /// Detail section: audit entries
  ///
  /// In en, this message translates to:
  /// **'Status history'**
  String get peopleHistory;

  /// Empty status history
  ///
  /// In en, this message translates to:
  /// **'No status changes yet.'**
  String get peopleHistoryEmpty;

  /// Who changed the status; role ID such as verifier
  ///
  /// In en, this message translates to:
  /// **'by {role}'**
  String peopleHistoryBy(String role);

  /// A08 heading
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providersTitle;

  /// A08 search box
  ///
  /// In en, this message translates to:
  /// **'Search providers by name or phone'**
  String get providersSearch;

  /// A08 empty list
  ///
  /// In en, this message translates to:
  /// **'No providers match these filters.'**
  String get providersEmpty;

  /// Link back to the A08 list
  ///
  /// In en, this message translates to:
  /// **'All providers'**
  String get providersAll;

  /// Filter and column: verification level
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get providersLevel;

  /// Level 0 (PRD §6.1)
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get providersLevel0;

  /// Level 1
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get providersLevel1;

  /// Level 2
  ///
  /// In en, this message translates to:
  /// **'PAO Verified Pro'**
  String get providersLevel2;

  /// Filter and badge: provider flagged by quality thresholds
  ///
  /// In en, this message translates to:
  /// **'Flagged for review'**
  String get providersFlagged;

  /// Badge: provider is online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get providersOnline;

  /// Column and fact: completed jobs
  ///
  /// In en, this message translates to:
  /// **'Jobs done'**
  String get providersJobs;

  /// A08 detail section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get providersProfile;

  /// Fact: services offered
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get providersServices;

  /// Fact: complaint count
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get providersComplaints;

  /// Fact: cancellations in the last 30 days
  ///
  /// In en, this message translates to:
  /// **'Cancellations (30 days)'**
  String get providersCancellations;

  /// Fact
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get providersGender;

  /// Gender
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get providersGenderFemale;

  /// Gender
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get providersGenderMale;

  /// Gender
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get providersGenderOther;

  /// Fact
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get providersExperience;

  /// Years of experience
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String providersExperienceYears(String years);

  /// A08 detail section
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get providersVerification;

  /// No verification items
  ///
  /// In en, this message translates to:
  /// **'Nothing submitted yet.'**
  String get providersNoItems;

  /// Verification item not required
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get providersOptional;

  /// Document expiry
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String providersItemExpires(String date);

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get providersItemNid;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get providersItemSelfie;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Police clearance'**
  String get providersItemPoliceClearance;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get providersItemAddress;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get providersItemEmergencyContact;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Skill proof'**
  String get providersItemSkillProof;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get providersItemServiceArea;

  /// Verification item
  ///
  /// In en, this message translates to:
  /// **'Code of conduct'**
  String get providersItemCodeOfConduct;

  /// Verification item status
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get providersItemMissing;

  /// Verification item status
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get providersItemPending;

  /// Verification item status
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get providersItemApproved;

  /// Verification item status
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get providersItemRejected;

  /// Verification item status
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get providersItemExpired;

  /// Provider ban dialog title (PRD §6.4)
  ///
  /// In en, this message translates to:
  /// **'Ban {name}? Their NID, phone and face cannot register again.'**
  String providersBanTitle(String name);

  /// Reason template
  ///
  /// In en, this message translates to:
  /// **'Repeated no-shows'**
  String get providersReasonNoShow;

  /// Reason template
  ///
  /// In en, this message translates to:
  /// **'Verified complaint'**
  String get providersReasonComplaint;

  /// Reason template
  ///
  /// In en, this message translates to:
  /// **'Rating below the floor'**
  String get providersReasonRating;

  /// Reason template
  ///
  /// In en, this message translates to:
  /// **'Forged documents'**
  String get providersReasonFraud;

  /// A09 heading
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// A09 search box
  ///
  /// In en, this message translates to:
  /// **'Search customers by name or phone'**
  String get customersSearch;

  /// A09 empty list
  ///
  /// In en, this message translates to:
  /// **'No customers match these filters.'**
  String get customersEmpty;

  /// Link back to the A09 list
  ///
  /// In en, this message translates to:
  /// **'All customers'**
  String get customersAll;

  /// Column and fact: booking count
  ///
  /// In en, this message translates to:
  /// **'Total bookings'**
  String get customersBookings;

  /// A09 detail section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get customersProfile;

  /// A09 detail section
  ///
  /// In en, this message translates to:
  /// **'Complaints and reports'**
  String get customersComplaints;

  /// No complaints
  ///
  /// In en, this message translates to:
  /// **'No complaints yet.'**
  String get customersNoComplaints;

  /// Reason template
  ///
  /// In en, this message translates to:
  /// **'Abusive behaviour'**
  String get customersReasonAbuse;

  /// Reason template
  ///
  /// In en, this message translates to:
  /// **'Repeated fake bookings'**
  String get customersReasonFake;

  /// Reason template
  ///
  /// In en, this message translates to:
  /// **'Refused to pay'**
  String get customersReasonPayment;

  /// A10 heading
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsTitle;

  /// A10 auto-refresh note
  ///
  /// In en, this message translates to:
  /// **'Refreshes every {seconds} seconds'**
  String bookingsAutoRefresh(String seconds);

  /// A10 area box
  ///
  /// In en, this message translates to:
  /// **'Filter by area, e.g. Banani'**
  String get bookingsAreaHint;

  /// A10 date filter, none set
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get bookingsAnyDate;

  /// A10 clears the date filter
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get bookingsClearDates;

  /// A10 empty list
  ///
  /// In en, this message translates to:
  /// **'No bookings match these filters.'**
  String get bookingsEmpty;

  /// Link back to the A10 list
  ///
  /// In en, this message translates to:
  /// **'All bookings'**
  String get bookingsAll;

  /// Column: booking number
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get bookingsNumber;

  /// Column and fact
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get bookingsService;

  /// Column and fact: creation time
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get bookingsCreated;

  /// Column and fact
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingsTotal;

  /// Fact
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get bookingsWhen;

  /// Timing: ASAP
  ///
  /// In en, this message translates to:
  /// **'As soon as possible'**
  String get bookingsAsap;

  /// Fact: end of a duration hire
  ///
  /// In en, this message translates to:
  /// **'Hire ends'**
  String get bookingsEnds;

  /// Fact: in progress at
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get bookingsStarted;

  /// Fact: completed at
  ///
  /// In en, this message translates to:
  /// **'Work completed'**
  String get bookingsFinished;

  /// Fact
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get bookingsPayment;

  /// Payment method
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get bookingsCash;

  /// Payment confirmed
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get bookingsCashReceived;

  /// Fact
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bookingsAddress;

  /// Fact
  ///
  /// In en, this message translates to:
  /// **'Customer note'**
  String get bookingsNote;

  /// Fact: who cancelled; the value is the reason
  ///
  /// In en, this message translates to:
  /// **'Cancelled by {actor}'**
  String bookingsCancelledBy(String actor);

  /// A10 detail section
  ///
  /// In en, this message translates to:
  /// **'Customer and provider'**
  String get bookingsParties;

  /// Party and timeline actor
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get bookingsCustomer;

  /// Party and timeline actor
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get bookingsProvider;

  /// No provider on the booking
  ///
  /// In en, this message translates to:
  /// **'Not assigned yet'**
  String get bookingsNotAssigned;

  /// Timeline actor
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get bookingsActorSystem;

  /// Timeline actor
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get bookingsActorAdmin;

  /// A10 detail section
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get bookingsItems;

  /// Quantity times unit price
  ///
  /// In en, this message translates to:
  /// **'{quantity} × {price}'**
  String bookingsQty(String quantity, String price);

  /// Badge: line added during the job
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get bookingsExtra;

  /// A10 detail section
  ///
  /// In en, this message translates to:
  /// **'Proposed extras'**
  String get bookingsExtras;

  /// Extras status
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer'**
  String get bookingsExtrasPending;

  /// Extras status
  ///
  /// In en, this message translates to:
  /// **'Approved by the customer'**
  String get bookingsExtrasApproved;

  /// Extras status
  ///
  /// In en, this message translates to:
  /// **'Declined by the customer'**
  String get bookingsExtrasDeclined;

  /// Extras amounts
  ///
  /// In en, this message translates to:
  /// **'Adds {added}; new total {total}'**
  String bookingsExtrasAdded(String added, String total);

  /// A10 detail section
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get bookingsTimeline;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Requested'**
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
  /// **'Rejected'**
  String get bookingsStatusRejected;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get bookingsStatusTimedOut;

  /// Booking status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingsStatusCancelled;

  /// A11 heading
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaintsTitle;

  /// A11 filter
  ///
  /// In en, this message translates to:
  /// **'Assigned to me'**
  String get complaintsMine;

  /// A11 empty list
  ///
  /// In en, this message translates to:
  /// **'No complaints match these filters.'**
  String get complaintsEmpty;

  /// Link back to the A11 list
  ///
  /// In en, this message translates to:
  /// **'All complaints'**
  String get complaintsAll;

  /// Column: ticket number
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get complaintsTicket;

  /// Column and fact
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get complaintsReason;

  /// Column and fact
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get complaintsReporter;

  /// Column and fact: creation time
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get complaintsOpened;

  /// Complaint status
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get complaintsStatusOpen;

  /// Complaint status
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get complaintsStatusAssigned;

  /// Complaint status
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get complaintsStatusResolved;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get complaintsReasonNoShow;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get complaintsReasonLate;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Poor quality'**
  String get complaintsReasonPoorQuality;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Overcharged'**
  String get complaintsReasonOvercharge;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Damage'**
  String get complaintsReasonDamage;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get complaintsReasonBehaviour;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get complaintsReasonSafety;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Customer unavailable'**
  String get complaintsReasonCustomerUnavailable;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get complaintsReasonPayment;

  /// Complaint reason
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get complaintsReasonOther;

  /// Reporter role
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get complaintsByCustomer;

  /// Reporter role
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get complaintsByProvider;

  /// Fact
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get complaintsAssignee;

  /// No assignee
  ///
  /// In en, this message translates to:
  /// **'Nobody yet'**
  String get complaintsUnassigned;

  /// The signed-in admin
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get complaintsYou;

  /// Another admin, by short ID
  ///
  /// In en, this message translates to:
  /// **'Agent {id}'**
  String complaintsAgent(String id);

  /// Complaint description heading
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get complaintsDescription;

  /// Link to A10 detail
  ///
  /// In en, this message translates to:
  /// **'Open the booking'**
  String get complaintsOpenBooking;

  /// Link to the reporter
  ///
  /// In en, this message translates to:
  /// **'Reporter\'s profile'**
  String get complaintsReporterProfile;

  /// Link to the person complained about
  ///
  /// In en, this message translates to:
  /// **'Other party\'s profile'**
  String get complaintsAgainstProfile;

  /// A11 detail section
  ///
  /// In en, this message translates to:
  /// **'Evidence photos'**
  String get complaintsEvidence;

  /// No evidence
  ///
  /// In en, this message translates to:
  /// **'No photos attached.'**
  String get complaintsNoEvidence;

  /// One evidence photo
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String complaintsPhoto(String number);

  /// The API has no signed URL for complaint photos yet
  ///
  /// In en, this message translates to:
  /// **'Opening complaint photos here is not available yet.'**
  String get complaintsPhotoPending;

  /// A11 detail section
  ///
  /// In en, this message translates to:
  /// **'Internal comments'**
  String get complaintsComments;

  /// No comments
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get complaintsNoComments;

  /// Comment box
  ///
  /// In en, this message translates to:
  /// **'Add a note for the team'**
  String get complaintsCommentHint;

  /// Comment button
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get complaintsCommentSend;

  /// Comment saved
  ///
  /// In en, this message translates to:
  /// **'Comment added.'**
  String get complaintsCommented;

  /// A11 detail section
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get complaintsActions;

  /// Assign action
  ///
  /// In en, this message translates to:
  /// **'Assign to me'**
  String get complaintsAssignMe;

  /// Assign action
  ///
  /// In en, this message translates to:
  /// **'Assign to another agent'**
  String get complaintsAssignOther;

  /// Agent picker title
  ///
  /// In en, this message translates to:
  /// **'Choose a support agent'**
  String get complaintsPickAgent;

  /// Agent picker empty
  ///
  /// In en, this message translates to:
  /// **'No active support agents.'**
  String get complaintsNoAgents;

  /// Assign succeeded
  ///
  /// In en, this message translates to:
  /// **'Complaint assigned.'**
  String get complaintsAssigned;

  /// Resolve action
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get complaintsResolve;

  /// Resolve dialog title
  ///
  /// In en, this message translates to:
  /// **'Resolve {ticket}'**
  String complaintsResolveTitle(String ticket);

  /// Resolve dialog field
  ///
  /// In en, this message translates to:
  /// **'Resolution note'**
  String get complaintsResolution;

  /// Resolve checkbox and badge
  ///
  /// In en, this message translates to:
  /// **'Verified complaint'**
  String get complaintsVerified;

  /// Resolve checkbox help (PRD §6.4)
  ///
  /// In en, this message translates to:
  /// **'A verified complaint feeds the provider\'s quality review.'**
  String get complaintsVerifiedHelp;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get complaintsNotVerified;

  /// Resolve succeeded
  ///
  /// In en, this message translates to:
  /// **'Complaint resolved.'**
  String get complaintsResolved;

  /// A11 detail section
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get complaintsResolutionTitle;
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
