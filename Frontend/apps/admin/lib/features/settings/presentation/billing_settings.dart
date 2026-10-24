import 'package:pao_admin/features/billing/presentation/billing_labels.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// PAO's commission in basis points of the final job price (ADR-0035 §2).
const commissionRateKey = 'billing.commission_rate_bp';

/// The due in paisa above which a merchant cannot accept (ADR-0035 §3).
const dueBlockKey = 'billing.due_block_amount';

/// The highest rate: 10000 basis points is the whole price.
const maxRateBp = 10000;

/// Why [value] is not valid for billing setting [key], or null when it is or
/// [key] is not a billing setting.
String? checkBillingSetting(AdminL10n t, String key, String value) {
  final n = int.tryParse(value.trim());
  return switch (key) {
    commissionRateKey when n == null || n < 0 || n > maxRateBp =>
      t.settingsRateRange,
    dueBlockKey when n == null || n < 0 => t.settingsAmountRange,
    _ => null,
  };
}

/// What the value of billing setting [key] means, or null for other keys.
String? billingSettingValue(AdminL10n t, String key, String value) {
  final n = int.tryParse(value);
  if (n == null) return null;
  return switch (key) {
    commissionRateKey => t.settingsRateValue(percentOf(n), value),
    dueBlockKey => formatMoney(n),
    _ => null,
  };
}

/// How to enter billing setting [key], or null for other keys.
String? billingSettingHint(AdminL10n t, String key) => switch (key) {
  commissionRateKey => t.settingsRateHint,
  dueBlockKey => t.settingsAmountHint,
  _ => null,
};
