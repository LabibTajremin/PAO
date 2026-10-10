// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'partner_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PartnerL10nEn extends PartnerL10n {
  PartnerL10nEn([String locale = 'en']) : super(locale);

  @override
  String get partnerTitle => 'PAO Partner';

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
  String get onbTagline => 'Work on your own terms';

  @override
  String get onbLanguage => 'Language';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbSlide1Title => 'Get jobs near you';

  @override
  String get onbSlide1Body =>
      'Customers nearby book your services. Accept the jobs that suit you.';

  @override
  String get onbSlide2Title => 'Fixed prices, cash in hand';

  @override
  String get onbSlide2Body =>
      'PAO sets the prices, so there is no haggling. Customers pay you in cash when the job is done.';

  @override
  String get onbSlide3Title => 'Verified and trusted';

  @override
  String get onbSlide3Body =>
      'Verify your documents once to earn the Verified badge and start getting requests.';

  @override
  String get enrolTitle => 'Enrolment';

  @override
  String enrolStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get enrolStepPersonal => 'Personal information';

  @override
  String get enrolStepServices => 'Your services';

  @override
  String get enrolStepArea => 'Service area';

  @override
  String get enrolStepNid => 'National ID';

  @override
  String get enrolStepSelfie => 'Live selfie';

  @override
  String get enrolStepPolice => 'Police clearance';

  @override
  String get enrolStepSkill => 'Skill proof';

  @override
  String get enrolStepContact => 'Emergency contact';

  @override
  String get enrolStepConduct => 'Code of conduct';

  @override
  String get enrolReviewTitle => 'Review and submit';

  @override
  String get enrolSaveContinue => 'Save and continue';

  @override
  String get enrolSkip => 'Skip for now';

  @override
  String get enrolPickDate => 'Select a date';

  @override
  String get enrolNameLabel => 'Full name (as on your NID)';

  @override
  String get enrolNameError => 'Enter your full name as written on your NID.';

  @override
  String get enrolDobLabel => 'Date of birth';

  @override
  String get enrolDobError => 'You must be at least 18 years old.';

  @override
  String get enrolGenderLabel => 'Gender';

  @override
  String get enrolGenderFemale => 'Female';

  @override
  String get enrolGenderMale => 'Male';

  @override
  String get enrolGenderOther => 'Other';

  @override
  String get enrolGenderError => 'Choose your gender.';

  @override
  String get enrolPresentAddress => 'Present address';

  @override
  String get enrolPermanentAddress => 'Permanent address';

  @override
  String get enrolAddressError => 'Enter a full address.';

  @override
  String get enrolServicesHint => 'Choose up to 5 services you offer.';

  @override
  String get enrolServicesError => 'Choose at least one service.';

  @override
  String get enrolServicesEmpty => 'No services are open for enrolment yet.';

  @override
  String get enrolExperience => 'Years of experience';

  @override
  String get enrolAreaHint =>
      'Set your home base. You will get requests within your working radius.';

  @override
  String get enrolAreaLocate => 'Use my current location';

  @override
  String get enrolAreaNoPin => 'No location set yet';

  @override
  String enrolAreaPinned(String lat, String lng) {
    return 'Home base: $lat, $lng';
  }

  @override
  String get enrolAreaOff =>
      'Turn on location and allow PAO Partner to use it.';

  @override
  String get enrolAreaError => 'Set your home base first.';

  @override
  String enrolAreaRadius(int km) {
    return 'Working radius: $km km';
  }

  @override
  String get enrolNidNumber => 'NID number';

  @override
  String get enrolNidError => 'Enter the 10, 13 or 17-digit NID number.';

  @override
  String get enrolNidFront => 'Front of the card';

  @override
  String get enrolNidBack => 'Back of the card';

  @override
  String get enrolPhotoError => 'Add every photo before you continue.';

  @override
  String get enrolTakePhoto => 'Take photo';

  @override
  String get enrolChoosePhoto => 'Choose from gallery';

  @override
  String get enrolRetake => 'Retake';

  @override
  String enrolUploading(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get enrolUploaded => 'Uploaded';

  @override
  String get enrolUploadFailed => 'Upload failed.';

  @override
  String get enrolSelfieHint =>
      'Hold the phone at eye level in good light, take off sunglasses or a cap, and look at the camera.';

  @override
  String get enrolPoliceHint =>
      'Add your police clearance certificate. It must be issued within the last 12 months.';

  @override
  String get enrolIssueDate => 'Issue date';

  @override
  String get enrolIssueDateError => 'Enter the issue date.';

  @override
  String get enrolSkillHint =>
      'Optional: add training certificates or photos of your work. They help you reach Level 2.';

  @override
  String enrolSkillPhoto(int number) {
    return 'Photo $number';
  }

  @override
  String get enrolContactHint =>
      'Someone we can call in an emergency. We will text them a code to confirm.';

  @override
  String get enrolContactName => 'Name';

  @override
  String get enrolContactRelation => 'Relation';

  @override
  String get enrolContactPhone => 'Mobile number';

  @override
  String get enrolContactNameError => 'Enter their name.';

  @override
  String get enrolContactRelationError => 'Enter how you are related.';

  @override
  String get enrolContactPhoneError =>
      'Enter an 11-digit Bangladeshi mobile number.';

  @override
  String get enrolContactSendCode => 'Send code';

  @override
  String enrolContactCodeSent(String phone) {
    return 'Enter the code we sent to $phone.';
  }

  @override
  String get enrolContactResend => 'Send the code again';

  @override
  String get enrolContactChange => 'Change contact';

  @override
  String get enrolConductIntro => 'As a PAO partner, I will:';

  @override
  String get enrolConductRule1 =>
      'Treat every customer with respect and keep their home and belongings safe.';

  @override
  String get enrolConductRule2 =>
      'Arrive on time and tell the customer if I am delayed.';

  @override
  String get enrolConductRule3 => 'Charge only the price shown in the app.';

  @override
  String get enrolConductRule4 =>
      'Never ask a customer for favours, extra money or contact outside PAO.';

  @override
  String get enrolConductRule5 =>
      'Never work under the influence of alcohol or drugs.';

  @override
  String get enrolConductAccept =>
      'I have read and accept the code of conduct.';

  @override
  String get enrolReviewBody =>
      'Check that every step is complete, then submit for verification.';

  @override
  String get enrolSubmittedBody => 'Your enrolment has been submitted.';

  @override
  String get enrolSubmit => 'Submit for verification';

  @override
  String get enrolGoVerification => 'See verification status';

  @override
  String get enrolStepDone => 'Done';

  @override
  String get enrolStepTodo => 'To do';

  @override
  String get enrolOptional => 'Optional';

  @override
  String get verifTitle => 'Verification';

  @override
  String verifLevel(int level) {
    return 'Level $level';
  }

  @override
  String get verifBadgeNone => 'Not verified yet';

  @override
  String get verifBadgeVerified => 'Verified';

  @override
  String get verifBadgePro => 'PAO Verified Pro';

  @override
  String get verifCleared => 'You are verified and can receive bookings.';

  @override
  String get verifIncomplete =>
      'Finish your enrolment so we can check your documents.';

  @override
  String get verifAttention =>
      'Some items need your attention. Upload them again below.';

  @override
  String get verifPending =>
      'We are checking your documents. This usually takes up to 48 hours.';

  @override
  String get verifGoHome => 'Go to home';

  @override
  String get verifContinue => 'Continue enrolment';

  @override
  String get verifSubmit => 'Review and submit';

  @override
  String get verifItemsTitle => 'Documents';

  @override
  String get verifNoItems => 'No documents yet.';

  @override
  String get verifItemNid => 'National ID';

  @override
  String get verifItemSelfie => 'Live selfie';

  @override
  String get verifItemPolice => 'Police clearance';

  @override
  String get verifItemAddress => 'Address';

  @override
  String get verifItemContact => 'Emergency contact';

  @override
  String get verifItemSkill => 'Skill proof';

  @override
  String get verifItemArea => 'Services and area';

  @override
  String get verifItemConduct => 'Code of conduct';

  @override
  String get verifStatusMissing => 'Missing';

  @override
  String get verifStatusPending => 'In review';

  @override
  String get verifStatusApproved => 'Approved';

  @override
  String get verifStatusRejected => 'Rejected';

  @override
  String get verifStatusExpired => 'Expired';

  @override
  String verifReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String verifExpires(String date) {
    return 'Valid until $date';
  }

  @override
  String verifExpired(String date) {
    return 'Expired on $date';
  }

  @override
  String get verifReupload => 'Upload again';

  @override
  String get verifLevel2Title => 'Level 2: skill check';

  @override
  String get verifLevel2Eligible =>
      'You can take a skill check to earn PAO Verified Pro. Our team will contact you to schedule it.';

  @override
  String get verifLevel2NotEligible =>
      'Reach Level 1 first, then you can take a skill check.';

  @override
  String verifLevel2Session(String date, String place) {
    return 'Skill check on $date at $place';
  }

  @override
  String verifLevel2Retry(String date) {
    return 'You can try again after $date.';
  }
}
