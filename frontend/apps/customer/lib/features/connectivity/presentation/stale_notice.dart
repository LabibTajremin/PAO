import 'package:flutter/material.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Tells the customer that a booking screen shows the last known status
/// because it could not be refreshed (C36).
class StaleNotice extends StatelessWidget {
  /// Creates the notice.
  const StaleNotice({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PaoSpace.md),
    child: PaoBanner(message: context.t.connectivityStale),
  );
}
