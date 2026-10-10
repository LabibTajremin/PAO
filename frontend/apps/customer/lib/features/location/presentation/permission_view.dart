import 'package:flutter/material.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Why PAO asks for the location, shown before the system prompt (C34).
class PermissionView extends StatelessWidget {
  /// Creates the view.
  const PermissionView({
    required this.onAllow,
    required this.onManual,
    super.key,
  });

  /// Reads the device position.
  final VoidCallback onAllow;

  /// Skips to typing the address.
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) => PaoMessageState(
    icon: Icons.my_location,
    title: context.t.locPermTitle,
    message: context.t.locPermBody,
    action: Column(
      children: [
        PaoButton(label: context.t.locPermAllow, onPressed: onAllow),
        const SizedBox(height: PaoSpace.sm),
        PaoButton(
          label: context.t.locPermManual,
          variant: PaoButtonVariant.ghost,
          onPressed: onManual,
        ),
      ],
    ),
  );
}
