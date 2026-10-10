import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/account/presentation/addresses_cubit.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

enum _Action { makeDefault, edit, delete }

/// One saved address with its actions (C24).
class AddressCard extends StatelessWidget {
  /// Creates the card.
  const AddressCard({required this.address, super.key});

  /// The address.
  final Address address;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = address;
    final isDefault = a.isDefault ?? false;
    final (icon, label) = switch (a.label) {
      AddressLabel.home => (Icons.home_outlined, t.accountAddressHome),
      AddressLabel.office => (Icons.work_outline, t.accountAddressOffice),
      AddressLabel.other => (Icons.place_outlined, t.accountAddressOther),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: PaoSpace.md),
      child: PaoCard(
        padding: EdgeInsets.zero,
        child: PaoListRow(
          leading: Icon(icon),
          title: label,
          subtitle: [a.line1, ?a.line2, ?a.area].join(', '),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDefault)
                PaoBadge(label: t.accountAddressDefault, tone: PaoTone.accent),
              _menu(
                t,
                isDefault: isDefault,
                onSelected: (action) => _run(context, action),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(
    CustomerL10n t, {
    required bool isDefault,
    required ValueChanged<_Action> onSelected,
  }) => PopupMenuButton<_Action>(
    tooltip: t.accountAddressActions,
    onSelected: onSelected,
    itemBuilder: (_) => [
      if (!isDefault)
        PopupMenuItem(
          value: _Action.makeDefault,
          child: Text(t.accountAddressMakeDefault),
        ),
      PopupMenuItem(value: _Action.edit, child: Text(t.accountAddressEdit)),
      PopupMenuItem(value: _Action.delete, child: Text(t.accountAddressDelete)),
    ],
  );

  Future<void> _run(BuildContext context, _Action action) async {
    final cubit = context.read<AddressesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final common = context.common;
    final failure = await switch (action) {
      _Action.makeDefault => cubit.makeDefault(address.id),
      _Action.edit => _edit(context, cubit),
      _Action.delete => _delete(context, cubit),
    };
    if (failure == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(failureMessage(common, failure.code))),
    );
  }

  Future<AppFailure?> _edit(BuildContext context, AddressesCubit cubit) async {
    await context.push<void>(Routes.addressEdit(address.id));
    await cubit.refresh();
    return null;
  }

  Future<AppFailure?> _delete(
    BuildContext context,
    AddressesCubit cubit,
  ) async {
    final t = context.t;
    final confirmed = await showPaoSheet<bool>(
      context,
      title: t.accountAddressDeleteTitle,
      child: Builder(
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.accountAddressDeleteBody),
            const SizedBox(height: PaoSpace.xl),
            PaoButton(
              label: t.accountAddressDelete,
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
    if (!(confirmed ?? false)) return null;
    return await cubit.delete(address.id);
  }
}
