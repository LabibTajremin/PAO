import 'package:flutter/widgets.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_partner/shared/formats.dart';

/// How a merchant can pay PAO, in the order the pay screen offers them.
Map<PaymentMethodKind, String> paymentMethods(PartnerL10n t) => {
  PaymentMethodKind.cashToAgent: t.payCashToAgent,
  PaymentMethodKind.bkash: t.payBkash,
  PaymentMethodKind.nagad: t.payNagad,
  PaymentMethodKind.bank: t.payBank,
};

/// The label of a submission [status].
String paymentStatusText(PartnerL10n t, PaymentSubmissionStatus status) =>
    switch (status) {
      PaymentSubmissionStatus.pending => t.billStatusPending,
      PaymentSubmissionStatus.confirmed => t.billStatusConfirmed,
      PaymentSubmissionStatus.rejected => t.billStatusRejected,
    };

/// Money in the app's language.
extension MoneyText on BuildContext {
  /// [paisa] as taka, e.g. `৳500`.
  String money(int paisa) => formatMoney(paisa, locale: lang);

  /// A basis-point rate as a percentage, e.g. `10` for 1000.
  String percent(int bp) =>
      formatCount(bp ~/ 100, locale: lang) +
      (bp % 100 == 0 ? '' : '.${(bp % 100).toString().padLeft(2, '0')}');
}
