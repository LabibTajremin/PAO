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
  String get homeOnline => 'You are online';

  @override
  String get homeOffline => 'You are offline';

  @override
  String get homeOnlineBody => 'Customers nearby can send you requests.';

  @override
  String get homeOfflineBody => 'Go online to receive requests.';

  @override
  String get homeLocationOff =>
      'Turn on location to go online. It is shared only while you are online.';

  @override
  String get homePausedTitle => 'Requests paused';

  @override
  String get homePausedBody =>
      'A document has expired. Renew it to receive requests again.';

  @override
  String get homeRenew => 'Renew document';

  @override
  String homeExpiring(String date) {
    return 'A document expires on $date. Renew it to keep receiving requests.';
  }

  @override
  String get homeToday => 'Today\'s earnings';

  @override
  String homeJobsToday(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString jobs today',
      one: '1 job today',
    );
    return '$_temp0';
  }

  @override
  String get homeActiveJob => 'Active job';

  @override
  String get homeRequests => 'New requests';

  @override
  String get homeNoRequests => 'No requests right now';

  @override
  String get homeNoRequestsBody => 'Stay online to receive requests nearby.';

  @override
  String get reqTitle => 'New request';

  @override
  String reqTimeLeft(String time) {
    return '$time left to answer';
  }

  @override
  String get reqAsap => 'As soon as possible';

  @override
  String reqScheduled(String time) {
    return 'Scheduled for $time';
  }

  @override
  String reqDistance(String km) {
    return '$km km away';
  }

  @override
  String get reqNote => 'Customer note';

  @override
  String get reqAccept => 'Accept';

  @override
  String get reqReject => 'Reject';

  @override
  String get reqRejectTitle => 'Why are you rejecting?';

  @override
  String get reqReasonBusy => 'I am busy';

  @override
  String get reqReasonTooFar => 'Too far away';

  @override
  String get reqReasonNotMyService => 'Not my service';

  @override
  String get reqReasonOther => 'Other reason';

  @override
  String get reqExpiredTitle => 'This request is no longer open';

  @override
  String get reqExpiredBody =>
      'The time to answer passed or it was already answered.';

  @override
  String get jobLiveTitle => 'Active job';

  @override
  String get jobStatusRequested => 'Waiting for your answer';

  @override
  String get jobStepAccepted => 'Accepted';

  @override
  String get jobStepOnTheWay => 'On the way';

  @override
  String get jobStepArrived => 'Arrived';

  @override
  String get jobStepStarted => 'Job started';

  @override
  String get jobStepCompleted => 'Completed';

  @override
  String get jobStatusCancelled => 'Cancelled';

  @override
  String get jobStatusClosed => 'Closed';

  @override
  String get jobCustomer => 'Customer';

  @override
  String get jobActionNavigate => 'Directions';

  @override
  String get jobActionCall => 'Call';

  @override
  String get jobActionOnTheWay => 'I\'m on the way';

  @override
  String get jobActionArrived => 'I\'ve arrived';

  @override
  String get jobActionStart => 'Enter start code';

  @override
  String get jobActionExtras => 'Add extra items';

  @override
  String get jobActionComplete => 'Complete job';

  @override
  String get jobActionRate => 'Rate customer';

  @override
  String get jobActionOpenRequest => 'Open request';

  @override
  String get jobActionCancel => 'Cancel job';

  @override
  String get jobBackHome => 'Back to home';

  @override
  String get jobBackToJob => 'Back to job';

  @override
  String get jobTotal => 'Total';

  @override
  String jobQuantity(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Quantity $countString';
  }

  @override
  String jobExtraQuantity(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Extra · quantity $countString';
  }

  @override
  String get jobCancelTitle => 'Why are you cancelling?';

  @override
  String get jobCancelWarning =>
      'Cancelling after accepting lowers your ranking.';

  @override
  String get jobCancelEmergency => 'Emergency';

  @override
  String get jobCancelUnreachable => 'Customer not reachable';

  @override
  String get jobCancelUnsafe => 'Unsafe location';

  @override
  String get jobCancelOther => 'Other reason';

  @override
  String get jobNoteLabel => 'Note (optional)';

  @override
  String get jobCancelledTitle => 'This job was cancelled';

  @override
  String get jobCancelledByCustomer => 'The customer cancelled this job.';

  @override
  String get jobCancelledOther => 'It can no longer be worked on.';

  @override
  String get jobClosedTitle => 'This job is no longer active';

  @override
  String get jobStartTitle => 'Enter start code';

  @override
  String get jobStartBody =>
      'Ask the customer for the 4-digit code in their app.';

  @override
  String get jobExtrasTitle => 'Add extra items';

  @override
  String get jobExtrasEmpty => 'There are no extra items for this service.';

  @override
  String jobExtrasSend(String amount) {
    return 'Send to customer · $amount';
  }

  @override
  String get jobExtrasWaitingTitle => 'Waiting for the customer';

  @override
  String jobExtrasWaiting(String amount) {
    return 'The customer is asked to approve $amount of extra items.';
  }

  @override
  String get jobExtrasApproved => 'The customer approved the last extra items.';

  @override
  String get jobExtrasDeclined => 'The customer declined the last extra items.';

  @override
  String get jobCompleteTitle => 'Complete job';

  @override
  String jobCashReceived(String amount) {
    return 'I received $amount in cash';
  }

  @override
  String get jobRateTitle => 'Rate the customer';

  @override
  String get jobRateQuestion => 'How was this customer?';

  @override
  String jobRateStars(int stars) {
    final intl.NumberFormat starsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String starsString = starsNumberFormat.format(stars);

    return '$starsString out of 5 stars';
  }

  @override
  String get jobRateComment => 'Comment (optional)';

  @override
  String get jobRateSubmit => 'Submit rating';

  @override
  String get jobRateSkip => 'Skip';

  @override
  String get jobTagPolite => 'Polite';

  @override
  String get jobTagClearInstructions => 'Clear instructions';

  @override
  String get jobTagPaidPromptly => 'Paid promptly';

  @override
  String get jobTagSafePlace => 'Safe place';

  @override
  String get jobTagRude => 'Rude';

  @override
  String get jobTagUnclearInstructions => 'Unclear instructions';

  @override
  String get jobTagUnsafePlace => 'Unsafe place';

  @override
  String get notifReadAll => 'Mark all read';

  @override
  String get notifEmpty => 'No notifications yet';

  @override
  String get notifEmptyBody =>
      'Updates about requests, jobs and documents appear here.';
}
