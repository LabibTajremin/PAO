import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Status filter options; null shows every submission.
Map<PaymentSubmissionStatus?, String> paymentStatusOptions(AdminL10n t) => {
  null: t.peopleFilterAny,
  for (final s in PaymentSubmissionStatus.values) s: paymentStatusLabel(t, s),
};

/// A submission status as admins read it.
String paymentStatusLabel(AdminL10n t, PaymentSubmissionStatus s) =>
    switch (s) {
      PaymentSubmissionStatus.pending => t.payStatusPending,
      PaymentSubmissionStatus.confirmed => t.payStatusConfirmed,
      PaymentSubmissionStatus.rejected => t.payStatusRejected,
    };

/// Badge colour of a submission status.
PaoTone paymentStatusTone(PaymentSubmissionStatus s) => switch (s) {
  PaymentSubmissionStatus.pending => PaoTone.warning,
  PaymentSubmissionStatus.confirmed => PaoTone.success,
  PaymentSubmissionStatus.rejected => PaoTone.danger,
};

/// How the merchant paid.
String paymentMethodLabel(AdminL10n t, PaymentMethodKind m) => switch (m) {
  PaymentMethodKind.cashToAgent => t.payCashToAgent,
  PaymentMethodKind.bkash => t.payBkash,
  PaymentMethodKind.nagad => t.payNagad,
  PaymentMethodKind.bank => t.payBank,
};

/// A basis-point rate as a percentage, e.g. `10` for 1000 or `10.5` for 1050.
String percentOf(int bp) {
  final whole = bp ~/ 100;
  final rest = bp % 100;
  if (rest == 0) return '$whole';
  final digits = rest % 10 == 0
      ? '${rest ~/ 10}'
      : rest.toString().padLeft(2, '0');
  return '$whole.$digits';
}

/// The first block of an ID, enough to tell merchants apart in a table.
String shortId(String id) => id.split('-').first;
