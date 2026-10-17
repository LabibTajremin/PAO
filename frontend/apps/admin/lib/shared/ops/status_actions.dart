import 'package:flutter/material.dart';
import 'package:pao_admin/shared/confirm_reason.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// What the suspend and ban dialogs say for one kind of account.
class StatusPrompts {
  /// Creates the prompts.
  const StatusPrompts({
    required this.name,
    required this.banTitle,
    required this.templates,
  });

  /// The account holder's name.
  final String name;

  /// Title of the ban dialog, which may spell out what a ban blocks.
  final String banTitle;

  /// Reasons to start from when suspending or banning.
  final List<String> templates;
}

/// Suspend, ban and reinstate buttons for an account in [status]; each asks
/// for a reason before [onChange] runs (PRD §6.4).
class AccountStatusActions extends StatelessWidget {
  /// Creates the buttons.
  const AccountStatusActions({
    required this.status,
    required this.prompts,
    required this.onChange,
    super.key,
  });

  /// The account's current status.
  final AccountStatus status;

  /// Dialog wording.
  final StatusPrompts prompts;

  /// Applies the change.
  final Future<void> Function(AccountStatusChange change) onChange;

  Future<void> _ask(
    BuildContext context,
    AccountStatusChangeStatusEnum target,
  ) async {
    final t = context.t;
    final (title, confirm, templates) = switch (target) {
      AccountStatusChangeStatusEnum.suspended => (
        t.peopleSuspendTitle(prompts.name),
        t.peopleSuspend,
        prompts.templates,
      ),
      AccountStatusChangeStatusEnum.banned => (
        prompts.banTitle,
        t.peopleBan,
        prompts.templates,
      ),
      AccountStatusChangeStatusEnum.active => (
        t.peopleReinstateTitle(prompts.name),
        t.peopleReinstate,
        [t.peopleReasonResolved, t.peopleReasonAppeal],
      ),
    };
    final reason = await confirmWithReason(
      context,
      title: title,
      confirmLabel: confirm,
      templates: templates,
    );
    if (reason == null) return;
    await onChange(AccountStatusChange(status: target, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final blocked =
        status == AccountStatus.suspended || status == AccountStatus.banned;
    Widget button(
      String label,
      PaoButtonVariant variant,
      AccountStatusChangeStatusEnum target,
    ) => PaoButton(
      label: label,
      variant: variant,
      expand: false,
      onPressed: () => _ask(context, target),
    );
    return Wrap(
      spacing: PaoSpace.sm,
      runSpacing: PaoSpace.sm,
      children: [
        if (blocked)
          button(
            t.peopleReinstate,
            PaoButtonVariant.soft,
            AccountStatusChangeStatusEnum.active,
          )
        else
          button(
            t.peopleSuspend,
            PaoButtonVariant.outline,
            AccountStatusChangeStatusEnum.suspended,
          ),
        if (status != AccountStatus.banned)
          button(
            t.peopleBan,
            PaoButtonVariant.danger,
            AccountStatusChangeStatusEnum.banned,
          ),
      ],
    );
  }
}
