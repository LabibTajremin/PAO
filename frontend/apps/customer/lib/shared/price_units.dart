import 'package:flutter/widgets.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// What one quantity of a sub-service means, e.g. "per hour".
String unitLabel(CustomerL10n t, PriceUnit unit) => switch (unit) {
  PriceUnit.job => t.svcPerJob,
  PriceUnit.unit => t.svcPerUnit,
  PriceUnit.hour => t.svcPerHour,
  PriceUnit.day => t.svcPerDay,
};

/// A sub-service price with its unit, e.g. "৳500 per hour".
String priceWithUnit(BuildContext context, SubService sub) {
  final lang = Localizations.localeOf(context).languageCode;
  final t = CustomerL10n.of(context);
  return '${formatMoney(sub.price, locale: lang)} ${unitLabel(t, sub.unit)}';
}
