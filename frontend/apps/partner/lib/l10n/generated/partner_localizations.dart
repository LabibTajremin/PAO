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

  /// M01 tagline under the app name.
  ///
  /// In en, this message translates to:
  /// **'Work on your own terms'**
  String get onbTagline;

  /// M02 label of the language switch.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onbLanguage;

  /// M02 button that ends onboarding early.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// M02 button to the next slide.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// M02 button on the last slide.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbStart;

  /// M02 slide 1 title.
  ///
  /// In en, this message translates to:
  /// **'Get jobs near you'**
  String get onbSlide1Title;

  /// M02 slide 1 body.
  ///
  /// In en, this message translates to:
  /// **'Customers nearby book your services. Accept the jobs that suit you.'**
  String get onbSlide1Body;

  /// M02 slide 2 title.
  ///
  /// In en, this message translates to:
  /// **'Fixed prices, cash in hand'**
  String get onbSlide2Title;

  /// M02 slide 2 body.
  ///
  /// In en, this message translates to:
  /// **'PAO sets the prices, so there is no haggling. Customers pay you in cash when the job is done.'**
  String get onbSlide2Body;

  /// M02 slide 3 title.
  ///
  /// In en, this message translates to:
  /// **'Verified and trusted'**
  String get onbSlide3Title;

  /// M02 slide 3 body.
  ///
  /// In en, this message translates to:
  /// **'Verify your documents once to earn the Verified badge and start getting requests.'**
  String get onbSlide3Body;

  /// Enrolment wizard title while loading.
  ///
  /// In en, this message translates to:
  /// **'Enrolment'**
  String get enrolTitle;

  /// Wizard progress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String enrolStepOf(int current, int total);

  /// M05 title.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get enrolStepPersonal;

  /// M06 title.
  ///
  /// In en, this message translates to:
  /// **'Your services'**
  String get enrolStepServices;

  /// M07 title.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get enrolStepArea;

  /// M08 title.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get enrolStepNid;

  /// M09 title.
  ///
  /// In en, this message translates to:
  /// **'Live selfie'**
  String get enrolStepSelfie;

  /// M10 title.
  ///
  /// In en, this message translates to:
  /// **'Police clearance'**
  String get enrolStepPolice;

  /// M11 title.
  ///
  /// In en, this message translates to:
  /// **'Skill proof'**
  String get enrolStepSkill;

  /// M12 title.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get enrolStepContact;

  /// M13 title.
  ///
  /// In en, this message translates to:
  /// **'Code of conduct'**
  String get enrolStepConduct;

  /// Wizard review title.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get enrolReviewTitle;

  /// Wizard main button.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get enrolSaveContinue;

  /// Skips the optional skill proof.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get enrolSkip;

  /// Empty date field.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get enrolPickDate;

  /// M05 name field.
  ///
  /// In en, this message translates to:
  /// **'Full name (as on your NID)'**
  String get enrolNameLabel;

  /// M05 name validation.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name as written on your NID.'**
  String get enrolNameError;

  /// M05 date of birth field.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get enrolDobLabel;

  /// M05 age rule.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old.'**
  String get enrolDobError;

  /// M05 gender label.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get enrolGenderLabel;

  /// Gender option.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get enrolGenderFemale;

  /// Gender option.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get enrolGenderMale;

  /// Gender option.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get enrolGenderOther;

  /// M05 gender validation.
  ///
  /// In en, this message translates to:
  /// **'Choose your gender.'**
  String get enrolGenderError;

  /// M05 field.
  ///
  /// In en, this message translates to:
  /// **'Present address'**
  String get enrolPresentAddress;

  /// M05 field.
  ///
  /// In en, this message translates to:
  /// **'Permanent address'**
  String get enrolPermanentAddress;

  /// M05 address validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a full address.'**
  String get enrolAddressError;

  /// M06 hint.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 services you offer.'**
  String get enrolServicesHint;

  /// M06 validation.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one service.'**
  String get enrolServicesError;

  /// M06 empty catalog.
  ///
  /// In en, this message translates to:
  /// **'No services are open for enrolment yet.'**
  String get enrolServicesEmpty;

  /// M06 experience stepper.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get enrolExperience;

  /// M07 hint.
  ///
  /// In en, this message translates to:
  /// **'Set your home base. You will get requests within your working radius.'**
  String get enrolAreaHint;

  /// M07 button.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get enrolAreaLocate;

  /// M07 map label without a pin.
  ///
  /// In en, this message translates to:
  /// **'No location set yet'**
  String get enrolAreaNoPin;

  /// M07 map label with coordinates.
  ///
  /// In en, this message translates to:
  /// **'Home base: {lat}, {lng}'**
  String enrolAreaPinned(String lat, String lng);

  /// M07 location unavailable.
  ///
  /// In en, this message translates to:
  /// **'Turn on location and allow PAO Partner to use it.'**
  String get enrolAreaOff;

  /// M07 validation.
  ///
  /// In en, this message translates to:
  /// **'Set your home base first.'**
  String get enrolAreaError;

  /// M07 radius slider label.
  ///
  /// In en, this message translates to:
  /// **'Working radius: {km} km'**
  String enrolAreaRadius(int km);

  /// M08 field.
  ///
  /// In en, this message translates to:
  /// **'NID number'**
  String get enrolNidNumber;

  /// M08 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter the 10, 13 or 17-digit NID number.'**
  String get enrolNidError;

  /// M08 photo slot.
  ///
  /// In en, this message translates to:
  /// **'Front of the card'**
  String get enrolNidFront;

  /// M08 photo slot.
  ///
  /// In en, this message translates to:
  /// **'Back of the card'**
  String get enrolNidBack;

  /// Missing uploads.
  ///
  /// In en, this message translates to:
  /// **'Add every photo before you continue.'**
  String get enrolPhotoError;

  /// Opens the camera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get enrolTakePhoto;

  /// Opens the gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get enrolChoosePhoto;

  /// Replaces a photo.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get enrolRetake;

  /// Upload progress.
  ///
  /// In en, this message translates to:
  /// **'Uploading {percent}%'**
  String enrolUploading(int percent);

  /// Upload done.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get enrolUploaded;

  /// Upload failure, followed by the reason.
  ///
  /// In en, this message translates to:
  /// **'Upload failed.'**
  String get enrolUploadFailed;

  /// M09 guidance.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone at eye level in good light, take off sunglasses or a cap, and look at the camera.'**
  String get enrolSelfieHint;

  /// M10 hint.
  ///
  /// In en, this message translates to:
  /// **'Add your police clearance certificate. It must be issued within the last 12 months.'**
  String get enrolPoliceHint;

  /// M10 date field.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get enrolIssueDate;

  /// M10 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter the issue date.'**
  String get enrolIssueDateError;

  /// M11 hint.
  ///
  /// In en, this message translates to:
  /// **'Optional: add training certificates or photos of your work. They help you reach Level 2.'**
  String get enrolSkillHint;

  /// M11 photo slot.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String enrolSkillPhoto(int number);

  /// M12 hint.
  ///
  /// In en, this message translates to:
  /// **'Someone we can call in an emergency. We will text them a code to confirm.'**
  String get enrolContactHint;

  /// M12 field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get enrolContactName;

  /// M12 field.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get enrolContactRelation;

  /// M12 field.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get enrolContactPhone;

  /// M12 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter their name.'**
  String get enrolContactNameError;

  /// M12 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter how you are related.'**
  String get enrolContactRelationError;

  /// M12 validation.
  ///
  /// In en, this message translates to:
  /// **'Enter an 11-digit Bangladeshi mobile number.'**
  String get enrolContactPhoneError;

  /// M12 button.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get enrolContactSendCode;

  /// M12 code entry.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to {phone}.'**
  String enrolContactCodeSent(String phone);

  /// M12 resend.
  ///
  /// In en, this message translates to:
  /// **'Send the code again'**
  String get enrolContactResend;

  /// M12 edit contact.
  ///
  /// In en, this message translates to:
  /// **'Change contact'**
  String get enrolContactChange;

  /// M13 heading.
  ///
  /// In en, this message translates to:
  /// **'As a PAO partner, I will:'**
  String get enrolConductIntro;

  /// M13 rule.
  ///
  /// In en, this message translates to:
  /// **'Treat every customer with respect and keep their home and belongings safe.'**
  String get enrolConductRule1;

  /// M13 rule.
  ///
  /// In en, this message translates to:
  /// **'Arrive on time and tell the customer if I am delayed.'**
  String get enrolConductRule2;

  /// M13 rule.
  ///
  /// In en, this message translates to:
  /// **'Charge only the price shown in the app.'**
  String get enrolConductRule3;

  /// M13 rule.
  ///
  /// In en, this message translates to:
  /// **'Never ask a customer for favours, extra money or contact outside PAO.'**
  String get enrolConductRule4;

  /// M13 rule.
  ///
  /// In en, this message translates to:
  /// **'Never work under the influence of alcohol or drugs.'**
  String get enrolConductRule5;

  /// M13 checkbox.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the code of conduct.'**
  String get enrolConductAccept;

  /// Review body.
  ///
  /// In en, this message translates to:
  /// **'Check that every step is complete, then submit for verification.'**
  String get enrolReviewBody;

  /// Review body after submission.
  ///
  /// In en, this message translates to:
  /// **'Your enrolment has been submitted.'**
  String get enrolSubmittedBody;

  /// Review main button.
  ///
  /// In en, this message translates to:
  /// **'Submit for verification'**
  String get enrolSubmit;

  /// Review button after submission.
  ///
  /// In en, this message translates to:
  /// **'See verification status'**
  String get enrolGoVerification;

  /// Step badge.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get enrolStepDone;

  /// Step badge.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get enrolStepTodo;

  /// Step badge.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get enrolOptional;

  /// M14 title.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verifTitle;

  /// M14 verification level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String verifLevel(int level);

  /// Level 0 badge.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get verifBadgeNone;

  /// Level 1 badge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifBadgeVerified;

  /// Level 2 badge.
  ///
  /// In en, this message translates to:
  /// **'PAO Verified Pro'**
  String get verifBadgePro;

  /// M14 status when cleared.
  ///
  /// In en, this message translates to:
  /// **'You are verified and can receive bookings.'**
  String get verifCleared;

  /// M14 status before submission.
  ///
  /// In en, this message translates to:
  /// **'Finish your enrolment so we can check your documents.'**
  String get verifIncomplete;

  /// M14 status with rejected or expired items.
  ///
  /// In en, this message translates to:
  /// **'Some items need your attention. Upload them again below.'**
  String get verifAttention;

  /// M14 status while in review.
  ///
  /// In en, this message translates to:
  /// **'We are checking your documents. This usually takes up to 48 hours.'**
  String get verifPending;

  /// M14 button once cleared.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get verifGoHome;

  /// M14 button to the next missing step.
  ///
  /// In en, this message translates to:
  /// **'Continue enrolment'**
  String get verifContinue;

  /// M14 button when every step is done but not submitted.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get verifSubmit;

  /// M14 section heading.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get verifItemsTitle;

  /// M14 empty list.
  ///
  /// In en, this message translates to:
  /// **'No documents yet.'**
  String get verifNoItems;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get verifItemNid;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Live selfie'**
  String get verifItemSelfie;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Police clearance'**
  String get verifItemPolice;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get verifItemAddress;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get verifItemContact;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Skill proof'**
  String get verifItemSkill;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Services and area'**
  String get verifItemArea;

  /// Verification item.
  ///
  /// In en, this message translates to:
  /// **'Code of conduct'**
  String get verifItemConduct;

  /// Item status.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get verifStatusMissing;

  /// Item status.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get verifStatusPending;

  /// Item status.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get verifStatusApproved;

  /// Item status.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get verifStatusRejected;

  /// Item status.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get verifStatusExpired;

  /// Rejection reason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String verifReason(String reason);

  /// Document expiry.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String verifExpires(String date);

  /// Expired document.
  ///
  /// In en, this message translates to:
  /// **'Expired on {date}'**
  String verifExpired(String date);

  /// Re-upload button.
  ///
  /// In en, this message translates to:
  /// **'Upload again'**
  String get verifReupload;

  /// Level 2 card title.
  ///
  /// In en, this message translates to:
  /// **'Level 2: skill check'**
  String get verifLevel2Title;

  /// Level 2 eligible.
  ///
  /// In en, this message translates to:
  /// **'You can take a skill check to earn PAO Verified Pro. Our team will contact you to schedule it.'**
  String get verifLevel2Eligible;

  /// Level 2 not eligible.
  ///
  /// In en, this message translates to:
  /// **'Reach Level 1 first, then you can take a skill check.'**
  String get verifLevel2NotEligible;

  /// Scheduled Level 2 session.
  ///
  /// In en, this message translates to:
  /// **'Skill check on {date} at {place}'**
  String verifLevel2Session(String date, String place);

  /// Level 2 cooling-off.
  ///
  /// In en, this message translates to:
  /// **'You can try again after {date}.'**
  String verifLevel2Retry(String date);
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
