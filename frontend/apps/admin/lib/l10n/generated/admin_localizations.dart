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

  /// Form: a required field is empty
  ///
  /// In en, this message translates to:
  /// **'Fill this in.'**
  String get formRequired;

  /// Form: text too long
  ///
  /// In en, this message translates to:
  /// **'Keep it to {max} characters or fewer.'**
  String formTooLong(String max);

  /// Form: not an integer
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get formWhole;

  /// Form: not a number
  ///
  /// In en, this message translates to:
  /// **'Enter a number.'**
  String get formNumber;

  /// Form: number below the minimum
  ///
  /// In en, this message translates to:
  /// **'Enter {min} or more.'**
  String formAtLeast(String min);

  /// Form: number out of range
  ///
  /// In en, this message translates to:
  /// **'Enter a number from {min} to {max}.'**
  String formRange(String min, String max);

  /// Form: not a taka amount
  ///
  /// In en, this message translates to:
  /// **'Enter an amount in taka, such as 500 or 499.50.'**
  String get formMoney;

  /// Form: not an email
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get formEmail;

  /// Snackbar after a save
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get formSaved;

  /// A02 heading
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashTitle;

  /// A02 when the figures were generated
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String dashUpdated(String time);

  /// A02 reload button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get dashRefresh;

  /// A02 count of providers waiting for review
  ///
  /// In en, this message translates to:
  /// **'Pending verifications'**
  String get dashPendingVerifications;

  /// A02 count of unresolved complaints
  ///
  /// In en, this message translates to:
  /// **'Open complaints'**
  String get dashOpenComplaints;

  /// A02 share of bookings completed
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get dashCompletionRate;

  /// A02 bookings summed over the chart days
  ///
  /// In en, this message translates to:
  /// **'Bookings in this period'**
  String get dashBookings;

  /// A02 count of active providers
  ///
  /// In en, this message translates to:
  /// **'Active providers'**
  String get dashActiveProviders;

  /// A02 chart heading
  ///
  /// In en, this message translates to:
  /// **'Bookings per day'**
  String get dashBookingsPerDay;

  /// A02 chart legend, full bar
  ///
  /// In en, this message translates to:
  /// **'All bookings'**
  String get dashLegendTotal;

  /// A02 chart legend, dark part of the bar
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashLegendCompleted;

  /// A02 bar tooltip
  ///
  /// In en, this message translates to:
  /// **'{day}: {total} bookings, {completed} completed'**
  String dashDayTip(String day, String total, String completed);

  /// A02 chart without days
  ///
  /// In en, this message translates to:
  /// **'No bookings in this period yet.'**
  String get dashNoBookings;

  /// A02 breakdown heading
  ///
  /// In en, this message translates to:
  /// **'Providers by status'**
  String get dashProvidersByStatus;

  /// A02 breakdown heading
  ///
  /// In en, this message translates to:
  /// **'Providers by level'**
  String get dashProvidersByLevel;

  /// A02 empty breakdown
  ///
  /// In en, this message translates to:
  /// **'No providers yet.'**
  String get dashNoProviders;

  /// Provider status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dashStatusPending;

  /// Provider status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashStatusActive;

  /// Provider status
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get dashStatusSuspended;

  /// Provider status
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get dashStatusBanned;

  /// Verification level 0
  ///
  /// In en, this message translates to:
  /// **'Level 0 · Registered'**
  String get dashLevel0;

  /// Verification level 1
  ///
  /// In en, this message translates to:
  /// **'Level 1 · Verified'**
  String get dashLevel1;

  /// Verification level 2
  ///
  /// In en, this message translates to:
  /// **'Level 2 · PAO Verified Pro'**
  String get dashLevel2;

  /// A03 heading
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTitle;

  /// A03 catalog version under the heading
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String catalogVersion(String version);

  /// A03 empty catalog
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get catalogEmptyTitle;

  /// A03 empty catalog explanation
  ///
  /// In en, this message translates to:
  /// **'Add a category, then the services customers can book in it.'**
  String get catalogEmptyBody;

  /// A03 button and dialog title
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get catalogNewCategory;

  /// A03 dialog title and tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get catalogEditCategory;

  /// A03 category subtitle: name in the other language, sort order, number of services
  ///
  /// In en, this message translates to:
  /// **'{other} · order {order} · {count} services'**
  String catalogCategoryLine(String other, String order, String count);

  /// A03 add-service button, A04 title
  ///
  /// In en, this message translates to:
  /// **'New service'**
  String get catalogNewService;

  /// A04 title before the service loads
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get catalogServiceTitle;

  /// A04 back button tooltip
  ///
  /// In en, this message translates to:
  /// **'Back to catalog'**
  String get catalogBack;

  /// Badge: customers can see it
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get catalogPublished;

  /// Badge: customers cannot see it
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get catalogHidden;

  /// Switch title
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get catalogPublishedSwitch;

  /// Switch explanation
  ///
  /// In en, this message translates to:
  /// **'Customers see it in the apps.'**
  String get catalogPublishedHint;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catalogName;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get catalogDescription;

  /// Label of the English half of a two-language field
  ///
  /// In en, this message translates to:
  /// **'{label} (English)'**
  String catalogInEnglish(String label);

  /// Label of the Bangla half of a two-language field
  ///
  /// In en, this message translates to:
  /// **'{label} (Bangla)'**
  String catalogInBangla(String label);

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Icon key'**
  String get catalogIconKey;

  /// Icon menu tooltip
  ///
  /// In en, this message translates to:
  /// **'Pick a known icon'**
  String get catalogPickIcon;

  /// Field label; smaller shows first
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get catalogSortOrder;

  /// Adds a row to a list field
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get catalogAddRow;

  /// Removes a row from a list field
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get catalogRemoveRow;

  /// A04 form heading
  ///
  /// In en, this message translates to:
  /// **'Service details'**
  String get catalogServiceDetails;

  /// A04 dropdown label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get catalogCategory;

  /// A04 dropdown label
  ///
  /// In en, this message translates to:
  /// **'Service model'**
  String get catalogModel;

  /// A04 dropdown label
  ///
  /// In en, this message translates to:
  /// **'Required level'**
  String get catalogLevel;

  /// A04 field label
  ///
  /// In en, this message translates to:
  /// **'Search radius (metres)'**
  String get catalogRadius;

  /// A04 radius hint
  ///
  /// In en, this message translates to:
  /// **'From 500 to 50000'**
  String get catalogRadiusHint;

  /// A04 switch
  ///
  /// In en, this message translates to:
  /// **'Women providers only'**
  String get catalogWomenOnly;

  /// A04 switch explanation
  ///
  /// In en, this message translates to:
  /// **'Requests go only to women providers.'**
  String get catalogWomenOnlyHint;

  /// A04 switch
  ///
  /// In en, this message translates to:
  /// **'Requires Level 2'**
  String get catalogRequiresLevel2;

  /// A04 switch explanation
  ///
  /// In en, this message translates to:
  /// **'Providers pass an in-person skill check first.'**
  String get catalogRequiresLevel2Hint;

  /// A04 Level 2 checklist row label
  ///
  /// In en, this message translates to:
  /// **'Checklist item'**
  String get catalogChecklistItem;

  /// Service model
  ///
  /// In en, this message translates to:
  /// **'On-demand visit'**
  String get catalogModelOnDemand;

  /// Service model
  ///
  /// In en, this message translates to:
  /// **'Duration hire'**
  String get catalogModelDuration;

  /// Service model
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get catalogModelListing;

  /// Service model
  ///
  /// In en, this message translates to:
  /// **'Partner referral'**
  String get catalogModelPartner;

  /// Price unit
  ///
  /// In en, this message translates to:
  /// **'per job'**
  String get catalogUnitJob;

  /// Price unit
  ///
  /// In en, this message translates to:
  /// **'per unit'**
  String get catalogUnitUnit;

  /// Price unit
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get catalogUnitHour;

  /// Price unit
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get catalogUnitDay;

  /// A04 section heading
  ///
  /// In en, this message translates to:
  /// **'Sub-services'**
  String get catalogSubServices;

  /// A04 empty sub-service list
  ///
  /// In en, this message translates to:
  /// **'No sub-services yet. Add one so customers can book this service.'**
  String get catalogNoSubServices;

  /// A04 button and dialog title
  ///
  /// In en, this message translates to:
  /// **'New sub-service'**
  String get catalogNewSubService;

  /// A04 dialog title and tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit sub-service'**
  String get catalogEditSub;

  /// A04 sub-service maximum quantity
  ///
  /// In en, this message translates to:
  /// **'up to {count}'**
  String catalogMaxLine(String count);

  /// Sub-service inclusions list
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get catalogInclusion;

  /// Sub-service exclusions list
  ///
  /// In en, this message translates to:
  /// **'Not included'**
  String get catalogExclusion;

  /// Sub-service unit dropdown label
  ///
  /// In en, this message translates to:
  /// **'Priced'**
  String get catalogUnit;

  /// Sub-service maximum quantity label
  ///
  /// In en, this message translates to:
  /// **'Most per booking'**
  String get catalogMaxQuantity;

  /// Sub-service maximum quantity hint
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no limit'**
  String get catalogMaxQuantityHint;

  /// New sub-service first price
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get catalogFirstPrice;

  /// Tooltip of the prices button
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get catalogPrices;

  /// Price drawer title
  ///
  /// In en, this message translates to:
  /// **'Prices of {name}'**
  String catalogPricesOf(String name);

  /// Price drawer explanation
  ///
  /// In en, this message translates to:
  /// **'A new price applies to bookings made from now on. Earlier bookings keep the price they were made at.'**
  String get catalogPriceNote;

  /// Price drawer field
  ///
  /// In en, this message translates to:
  /// **'New price ({unit})'**
  String catalogNewPrice(String unit);

  /// Price drawer button
  ///
  /// In en, this message translates to:
  /// **'Set new price'**
  String get catalogSetPrice;

  /// Price drawer success
  ///
  /// In en, this message translates to:
  /// **'Price updated.'**
  String get catalogPriceChanged;

  /// Price drawer section
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get catalogPriceHistory;

  /// Price drawer empty history
  ///
  /// In en, this message translates to:
  /// **'No prices recorded yet.'**
  String get catalogNoPrices;

  /// Price version line: since when, which admin
  ///
  /// In en, this message translates to:
  /// **'From {when} · by {admin}'**
  String catalogPriceSince(String when, String admin);

  /// Badge on the price in force
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get catalogCurrentPrice;

  /// A12 heading
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// A12 tab
  ///
  /// In en, this message translates to:
  /// **'Platform settings'**
  String get settingsTabSettings;

  /// A12 tab
  ///
  /// In en, this message translates to:
  /// **'Admin users'**
  String get settingsTabAdmins;

  /// A12 tab
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get settingsTabRoles;

  /// A12 tab
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get settingsTabAudit;

  /// A12 empty settings list
  ///
  /// In en, this message translates to:
  /// **'No settings yet'**
  String get settingsEmpty;

  /// A12 settings search hint
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearch;

  /// A12 when a setting last changed
  ///
  /// In en, this message translates to:
  /// **'Changed {when}'**
  String settingsUpdatedAt(String when);

  /// A12 edit tooltip
  ///
  /// In en, this message translates to:
  /// **'Change setting'**
  String get settingsEdit;

  /// A12 setting value field
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get settingsValue;

  /// Boolean setting on
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsOn;

  /// Boolean setting off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// GeoJSON setting value
  ///
  /// In en, this message translates to:
  /// **'Map shape'**
  String get settingsShape;

  /// GeoJSON setting is not valid
  ///
  /// In en, this message translates to:
  /// **'Paste a GeoJSON object with a \"type\".'**
  String get settingsBadShape;

  /// Setting dialog note
  ///
  /// In en, this message translates to:
  /// **'The change applies right away and is recorded in the audit log.'**
  String get settingsApplyNow;

  /// Role
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get settingsRoleCustomer;

  /// Role
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get settingsRoleProvider;

  /// Role
  ///
  /// In en, this message translates to:
  /// **'Verifier'**
  String get settingsRoleVerifier;

  /// Role
  ///
  /// In en, this message translates to:
  /// **'Catalog manager'**
  String get settingsRoleCatalogManager;

  /// Role
  ///
  /// In en, this message translates to:
  /// **'Support agent'**
  String get settingsRoleSupportAgent;

  /// Role
  ///
  /// In en, this message translates to:
  /// **'Super admin'**
  String get settingsRoleSuperAdmin;

  /// Admin users button and dialog title
  ///
  /// In en, this message translates to:
  /// **'Invite admin'**
  String get adminsInvite;

  /// Invite dialog button
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get adminsSendInvite;

  /// Empty admin list
  ///
  /// In en, this message translates to:
  /// **'No admin users yet'**
  String get adminsEmpty;

  /// Invite field
  ///
  /// In en, this message translates to:
  /// **'Work email'**
  String get adminsEmail;

  /// Invite field
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get adminsName;

  /// Invite name too short
  ///
  /// In en, this message translates to:
  /// **'Write at least 2 characters.'**
  String get adminsNameShort;

  /// Role chips heading
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get adminsRoles;

  /// No role picked
  ///
  /// In en, this message translates to:
  /// **'Pick at least one role.'**
  String get adminsPickRole;

  /// Temporary password dialog title
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get adminsInvitedTitle;

  /// Temporary password explanation
  ///
  /// In en, this message translates to:
  /// **'Give this temporary password to {name} privately. It is shown only once; they replace it and set up 2FA when they first sign in.'**
  String adminsInvitedBody(String name);

  /// Copy button tooltip
  ///
  /// In en, this message translates to:
  /// **'Copy password'**
  String get adminsCopy;

  /// Snackbar after copying
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get adminsCopied;

  /// Close the temporary password dialog
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminsDone;

  /// Admin never signed in
  ///
  /// In en, this message translates to:
  /// **'Has not signed in yet'**
  String get adminsNeverSignedIn;

  /// Admin last sign-in
  ///
  /// In en, this message translates to:
  /// **'Last signed in {when}'**
  String adminsLastSignIn(String when);

  /// Admin status badge
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminsActive;

  /// Admin status badge
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get adminsInactive;

  /// Admin enrolled an authenticator
  ///
  /// In en, this message translates to:
  /// **'2FA set up'**
  String get adminsTotpOn;

  /// Admin has not enrolled an authenticator
  ///
  /// In en, this message translates to:
  /// **'2FA pending'**
  String get adminsTotpOff;

  /// Admin edit tooltip
  ///
  /// In en, this message translates to:
  /// **'Change roles or access'**
  String get adminsEdit;

  /// Admin active switch
  ///
  /// In en, this message translates to:
  /// **'Can sign in'**
  String get adminsActiveSwitch;

  /// Admin active switch explanation
  ///
  /// In en, this message translates to:
  /// **'Turning this off ends their sessions at once.'**
  String get adminsActiveHint;

  /// Deactivate confirmation title
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String adminsDeactivateTitle(String name);

  /// Deactivate confirmation body
  ///
  /// In en, this message translates to:
  /// **'They are signed out everywhere now and cannot sign in until reactivated.'**
  String get adminsDeactivateBody;

  /// Deactivate confirmation button
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminsDeactivate;

  /// Empty roles list
  ///
  /// In en, this message translates to:
  /// **'No roles found'**
  String get rolesEmpty;

  /// Roles warning
  ///
  /// In en, this message translates to:
  /// **'Role changes apply immediately to everyone who holds the role.'**
  String get rolesApplyNow;

  /// Role summary
  ///
  /// In en, this message translates to:
  /// **'{permissions} permissions · {screens} screens'**
  String rolesCounts(String permissions, String screens);

  /// Role edit tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit role'**
  String get rolesEdit;

  /// Role dialog section
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get rolesPermissions;

  /// Role dialog section
  ///
  /// In en, this message translates to:
  /// **'Screens'**
  String get rolesScreens;

  /// Role save confirmation title
  ///
  /// In en, this message translates to:
  /// **'Apply the changes to {role}?'**
  String rolesConfirmTitle(String role);

  /// Role save confirmation button
  ///
  /// In en, this message translates to:
  /// **'Apply now'**
  String get rolesApply;

  /// Snackbar after a role change
  ///
  /// In en, this message translates to:
  /// **'Role updated.'**
  String get rolesSaved;

  /// Audit column
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get auditWhen;

  /// Audit column
  ///
  /// In en, this message translates to:
  /// **'Who'**
  String get auditActor;

  /// Audit detail line
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get auditRole;

  /// Audit column
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditAction;

  /// Audit column
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get auditSubject;

  /// Audit detail line
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get auditReason;

  /// Audit detail line
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get auditBefore;

  /// Audit detail line
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get auditAfter;

  /// Audit entry without an actor
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get auditSystem;

  /// Empty audit list
  ///
  /// In en, this message translates to:
  /// **'No audit entries match'**
  String get auditEmpty;

  /// Audit filter
  ///
  /// In en, this message translates to:
  /// **'Actor ID'**
  String get auditActorId;

  /// Audit actor filter is not an ID
  ///
  /// In en, this message translates to:
  /// **'Paste a full account ID.'**
  String get auditActorInvalid;

  /// Audit filter
  ///
  /// In en, this message translates to:
  /// **'Action, e.g. catalog.price_changed'**
  String get auditActionHint;

  /// Audit filter
  ///
  /// In en, this message translates to:
  /// **'Subject ID'**
  String get auditSubjectId;

  /// Audit date filter without a range
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get auditAnyDate;

  /// Audit filter button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get auditApply;

  /// Audit filter reset
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get auditClear;
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
