import 'package:flutter/material.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Explains why PAO wants to send notifications, right before the phone's own
/// permission prompt. A one-time system prompt without context is often
/// declined, and then no booking update can pop up.
Future<void> showPushReason(BuildContext context) {
  final t = PaoL10n.of(context);
  return showPaoSheet<void>(
    context,
    title: t.pushReasonTitle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.pushReasonBody),
        const SizedBox(height: PaoSpace.xl),
        Builder(
          builder: (context) => PaoButton(
            label: t.pushReasonContinue,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    ),
  );
}
