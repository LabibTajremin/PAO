import 'package:flutter/widgets.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// Short access to the app's strings.
extension L10nContext on BuildContext {
  /// Customer app strings.
  CustomerL10n get t => CustomerL10n.of(this);

  /// Shared strings.
  PaoL10n get common => PaoL10n.of(this);

  /// The translated message for [failure], or null.
  String? failureText(AppFailure? failure) =>
      failure == null ? null : failureMessage(common, failure.code);
}
