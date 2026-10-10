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
