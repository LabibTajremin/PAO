import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pao_api/pao_api.dart' show BookingStatus, LocalizedText;
import 'package:pao_partner/shared/l10n.dart';

/// Helpers shared by the request and job screens.
extension JobText on BuildContext {
  /// The app language code, `en` or `bn`.
  String get lang => Localizations.localeOf(this).languageCode;

  /// [text] in the app language.
  String local(LocalizedText text) => lang == 'bn' ? text.bn : text.en;

  /// A duration as `m:ss` with the language's digits.
  String clock(Duration d) {
    final two = NumberFormat('00', lang);
    final seconds = d.inSeconds < 0 ? 0 : d.inSeconds;
    return '${NumberFormat('0', lang).format(seconds ~/ 60)}:'
        '${two.format(seconds % 60)}';
  }

  /// A short label for a job's status.
  String statusText(BookingStatus status) => switch (status) {
    BookingStatus.requested => t.jobStatusRequested,
    BookingStatus.accepted => t.jobStepAccepted,
    BookingStatus.onTheWay => t.jobStepOnTheWay,
    BookingStatus.arrived => t.jobStepArrived,
    BookingStatus.inProgress => t.jobStepStarted,
    BookingStatus.completed => t.jobStepCompleted,
    BookingStatus.cancelled => t.jobStatusCancelled,
    BookingStatus.rejected || BookingStatus.timedOut => t.jobStatusClosed,
  };

  /// Goes back when a screen was pushed, otherwise to [fallback], so deep
  /// links from push notifications never leave an empty stack.
  void leave(String fallback) => canPop() ? pop() : go(fallback);
}
