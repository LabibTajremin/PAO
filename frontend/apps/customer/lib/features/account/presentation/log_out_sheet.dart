import 'package:flutter/material.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/account/data/sign_out.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Asks before logging out (C30), then signs out.
Future<void> confirmLogOut(BuildContext context, AppServices services) async {
  final t = context.t;
  final confirmed = await showPaoSheet<bool>(
    context,
    title: t.accountLogOutTitle,
    child: Builder(
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.accountLogOutBody),
          const SizedBox(height: PaoSpace.xl),
          PaoButton(
            label: t.accountLogOut,
            variant: PaoButtonVariant.danger,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          PaoButton(
            label: sheet.common.actionCancel,
            variant: PaoButtonVariant.ghost,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    ),
  );
  if (confirmed ?? false) await signOut(services);
}
