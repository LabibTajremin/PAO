import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Goodbye after the account was deleted (C62); shown signed out.
class AccountDeletedPage extends StatelessWidget {
  /// Creates the page.
  const AccountDeletedPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PaoMessageState(
        icon: Icons.check_circle_outline,
        title: context.t.accountDeletedTitle,
        message: context.t.accountDeletedBody,
        action: PaoButton(
          label: context.common.actionContinue,
          expand: false,
          onPressed: () => context.go(Routes.phone),
        ),
      ),
    ),
  );
}
