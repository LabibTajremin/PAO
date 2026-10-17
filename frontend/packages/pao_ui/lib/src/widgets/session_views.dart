import 'package:flutter/material.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/src/widgets/button.dart';
import 'package:pao_ui/src/widgets/states.dart';

/// "Welcome back": the session expired and the user must sign in again (C63).
class PaoSessionExpiredView extends StatelessWidget {
  /// Creates the view; [onSignIn] opens the sign-in flow.
  const PaoSessionExpiredView({required this.onSignIn, super.key});

  /// Opens sign-in.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = PaoL10n.of(context);
    return PaoMessageState(
      icon: Icons.lock_clock_outlined,
      title: l10n.sessionExpiredTitle,
      message: l10n.sessionExpiredBody,
      action: PaoButton(label: l10n.actionContinue, onPressed: onSignIn),
    );
  }
}

/// Shown when the account's role may not open a screen.
class PaoAccessDeniedView extends StatelessWidget {
  /// Creates the view.
  const PaoAccessDeniedView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = PaoL10n.of(context);
    return PaoMessageState(
      icon: Icons.block_outlined,
      title: l10n.errorTitle,
      message: l10n.accessDenied,
    );
  }
}
