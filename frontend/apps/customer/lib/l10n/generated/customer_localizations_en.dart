// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'customer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CustomerL10nEn extends CustomerL10n {
  CustomerL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PAO';

  @override
  String get authPhoneTitle => 'What is your phone number?';

  @override
  String get authPhoneBody => 'We will text you a code to sign in.';

  @override
  String get authPhoneLabel => 'Mobile number';

  @override
  String get authPhoneInvalid => 'Enter an 11-digit Bangladeshi mobile number.';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authTermsNote =>
      'By continuing you agree to PAO\'s terms and privacy policy.';

  @override
  String get authTermsLink => 'Read the terms and privacy policy';

  @override
  String get authOtpTitle => 'Enter the 6-digit code';

  @override
  String authOtpSentTo(String phone) {
    return 'We sent it to $phone.';
  }

  @override
  String authResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get authResend => 'Resend code';

  @override
  String get authProfileTitle => 'Set up your profile';

  @override
  String get authProfileBody =>
      'Tell providers what to call you. A photo is optional.';

  @override
  String get authProfileName => 'Your name';

  @override
  String get authProfileNameInvalid => 'Enter a name of 2 to 80 characters.';

  @override
  String get authProfileAddPhoto => 'Add a photo';

  @override
  String get onbTagline => 'Trusted help at home';

  @override
  String get onbLanguage => 'Language';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbSlide1Title => 'Find help nearby';

  @override
  String get onbSlide1Body =>
      'Electricians, plumbers, cleaners and more, close to your home.';

  @override
  String get onbSlide2Title => 'Verified providers';

  @override
  String get onbSlide2Body =>
      'Every provider\'s NID, police clearance and skills are checked before they work.';

  @override
  String get onbSlide3Title => 'Fixed prices, pay in cash';

  @override
  String get onbSlide3Body =>
      'See the price before you book. Pay the provider in cash when the job is done.';

  @override
  String get locPermTitle => 'Find services near you';

  @override
  String get locPermBody =>
      'PAO reads your location once to set your address and show providers nearby. We never track you in the background.';

  @override
  String get locPermAllow => 'Allow location access';

  @override
  String get locPermManual => 'Enter address manually';

  @override
  String get locTitleSet => 'Set your location';

  @override
  String get locTitleNew => 'Add address';

  @override
  String get locTitleEdit => 'Edit address';

  @override
  String get locUseCurrent => 'Use my current location';

  @override
  String get locLocateFailed =>
      'We could not find your location. Search for your address or move the pin.';

  @override
  String get locDragHint => 'Drag the map to move the pin';

  @override
  String get locPinHere => 'Your pin';

  @override
  String get locSearch => 'Search for an address';

  @override
  String get locSearchHint => 'Road, area or landmark';

  @override
  String get locLabel => 'Save as';

  @override
  String get locLabelHome => 'Home';

  @override
  String get locLabelOffice => 'Office';

  @override
  String get locLabelOther => 'Other';

  @override
  String get locLine1 => 'House and road';

  @override
  String get locLine1Hint => 'House 12, Road 5, Block C';

  @override
  String get locLine1Invalid => 'Enter 3 to 200 characters.';

  @override
  String get locLine2 => 'Floor, flat or landmark (optional)';

  @override
  String get locArea => 'Area';

  @override
  String get locSave => 'Save address';

  @override
  String locCovered(String area) {
    return 'PAO works in $area';
  }

  @override
  String get locNotCoveredTitle => 'We are not here yet';

  @override
  String get locNotCoveredBody =>
      'PAO is not available at this location yet. You can still save it and book once we arrive.';

  @override
  String get homeAddressTitle => 'Your address';

  @override
  String get homeNoAddress => 'Set your address';

  @override
  String get homeNoAddressBody => 'Add your address to see services near you.';

  @override
  String get homeSearchHint => 'Search for a service';

  @override
  String get homeCategories => 'Services';

  @override
  String get homeAllServices => 'All services';

  @override
  String get homeNoServices => 'No services yet';

  @override
  String get homeAddressSheet => 'Choose address';

  @override
  String get homeAddAddress => 'Add a new address';

  @override
  String get homeNotCoveredBody =>
      'PAO is not available at this address yet. Choose another address to see services.';

  @override
  String get homeChangeAddress => 'Change address';

  @override
  String get homeActiveOpen => 'Track';

  @override
  String get homeStatusRequested => 'Waiting for the provider to accept';

  @override
  String get homeStatusAccepted => 'The provider accepted';

  @override
  String get homeStatusOnTheWay => 'The provider is on the way';

  @override
  String get homeStatusArrived => 'The provider has arrived';

  @override
  String get homeStatusInProgress => 'The job is in progress';

  @override
  String get searchHint => 'Search services, e.g. fan repair';

  @override
  String get searchPrompt => 'What do you need help with?';

  @override
  String get searchServices => 'Services';

  @override
  String get searchSubServices => 'Specific jobs';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchNoResultsBody =>
      'Check the spelling or try another word. You can also browse all services.';

  @override
  String get svcPerJob => 'per job';

  @override
  String get svcPerUnit => 'per unit';

  @override
  String get svcPerHour => 'per hour';

  @override
  String get svcPerDay => 'per day';

  @override
  String get svcIncluded => 'Included';

  @override
  String get svcExcluded => 'Not included';

  @override
  String get svcTotal => 'Total';

  @override
  String get svcChooseHint => 'Choose at least one item to continue.';

  @override
  String get svcWomenOnly => 'Only women providers do this service.';

  @override
  String get svcSeeProviders => 'See providers';

  @override
  String get svcFixedPrice =>
      'Prices are fixed by PAO. Pay in cash after the job.';

  @override
  String get svcNoItems => 'Nothing can be booked for this service yet.';

  @override
  String get svcHireStart => 'Start';

  @override
  String get svcHireDate => 'Choose a date';

  @override
  String get svcHireTime => 'Choose a time';

  @override
  String get svcHireDuty => 'Duty';

  @override
  String get svcHireStartPast => 'Choose a start time in the future.';

  @override
  String get svcHireNeedStart => 'Choose when the driver should start.';

  @override
  String svcHours(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n hours',
      one: '$n hour',
    );
    return '$_temp0';
  }

  @override
  String svcDays(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n days',
      one: '$n day',
    );
    return '$_temp0';
  }

  @override
  String get provTitle => 'Providers near you';

  @override
  String get provSortFilter => 'Sort & filter';

  @override
  String get provSort => 'Sort by';

  @override
  String get provSortDistance => 'Nearest';

  @override
  String get provSortRating => 'Top rated';

  @override
  String get provFilter => 'Show only';

  @override
  String get provFilterTopRated => '4 stars and above';

  @override
  String get provFilterPro => 'PAO Verified Pro';

  @override
  String get provApply => 'Apply';

  @override
  String get provEmptyTitle => 'No providers nearby right now';

  @override
  String get provEmptyBody =>
      'Providers come online throughout the day. Try again in a few minutes or change the filters.';

  @override
  String get provNoAddressTitle => 'Add your address first';

  @override
  String get provNoAddressBody =>
      'We need your address to find providers near you.';

  @override
  String get provNoDraft => 'Choose what you need on the service page first.';

  @override
  String get provChooseItems => 'Choose items';

  @override
  String get provPriceFor => 'Price for your selection';

  @override
  String provJobs(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n jobs done',
      one: '$n job done',
    );
    return '$_temp0';
  }

  @override
  String provKmAway(String km) {
    return '$km km away';
  }

  @override
  String provMAway(String m) {
    return '$m m away';
  }

  @override
  String get provBadgeNone => 'Not verified';

  @override
  String get provBadgeVerified => 'Verified';

  @override
  String get provBadgeVerifiedPro => 'PAO Verified Pro';

  @override
  String get provBadgeWhat => 'What do badges mean?';

  @override
  String get provBadgeSheet => 'About badges';

  @override
  String get provBadgeVerifiedBody =>
      'A PAO verifier checked their NID, selfie, police clearance, address and emergency contact.';

  @override
  String get provBadgeProBody =>
      'Verified, and PAO also checked their work in person with a skill test or a supervised job. Pros are listed higher.';

  @override
  String provExperience(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n years of experience',
      one: '$n year of experience',
    );
    return '$_temp0';
  }

  @override
  String provMemberSince(String date) {
    return 'On PAO since $date';
  }

  @override
  String get provServices => 'Services';

  @override
  String get provRatings => 'Ratings';

  @override
  String provRatingCount(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n ratings',
      one: '$n rating',
      zero: 'No ratings yet',
    );
    return '$_temp0';
  }

  @override
  String get provReviews => 'Recent reviews';

  @override
  String get provAllReviews => 'All reviews';

  @override
  String get provNoReviews => 'No reviews yet';

  @override
  String get provNoReviewsBody => 'Reviews appear here after completed jobs.';

  @override
  String provBook(String name) {
    return 'Book $name';
  }

  @override
  String get provAbout => 'About';

  @override
  String get provTagOnTime => 'On time';

  @override
  String get provTagProfessional => 'Professional';

  @override
  String get provTagQualityWork => 'Quality work';

  @override
  String get provTagClean => 'Clean';

  @override
  String get provTagFriendly => 'Friendly';

  @override
  String get provTagFairPrice => 'Fair price';

  @override
  String get provTagLate => 'Late';

  @override
  String get provTagRude => 'Rude';

  @override
  String get provTagPoorQuality => 'Poor quality';

  @override
  String get provTagMessy => 'Messy';

  @override
  String get provTagPolite => 'Polite';

  @override
  String get provTagClearInstructions => 'Clear instructions';

  @override
  String get provTagPaidPromptly => 'Paid promptly';

  @override
  String get provTagSafePlace => 'Safe place';

  @override
  String get provTagUnclearInstructions => 'Unclear instructions';

  @override
  String get provTagUnsafePlace => 'Unsafe place';
}
