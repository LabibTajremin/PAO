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
