import 'package:flutter/material.dart';
import 'package:pao_customer/features/booking/presentation/setup_cubit.dart';
import 'package:pao_customer/features/booking/presentation/setup_sections.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Shows the saved addresses (C46); picking one updates [cubit]. True when the
/// customer asked to add a new address instead.
Future<bool> showAddressSheet(BuildContext context, SetupCubit cubit) async {
  final add = await showPaoSheet<bool>(
    context,
    title: context.t.bookingAddressTitle,
    child: _AddressList(cubit: cubit),
  );
  return add ?? false;
}

class _AddressList extends StatelessWidget {
  const _AddressList({required this.cubit});

  final SetupCubit cubit;

  @override
  Widget build(BuildContext context) {
    final s = cubit.state;
    final t = context.t;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in s.options!.addresses)
          PaoListRow(
            leading: Icon(
              a.id == s.addressId
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: addressLabel(context, a),
            subtitle: addressLine(a),
            trailing: (a.isDefault ?? false)
                ? PaoBadge(label: t.bookingDefault)
                : null,
            onTap: () {
              cubit.address(a.id);
              Navigator.of(context).pop(false);
            },
          ),
        const SizedBox(height: PaoSpace.md),
        PaoButton(
          label: t.bookingAddAddress,
          icon: Icons.add_location_alt_outlined,
          variant: PaoButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
