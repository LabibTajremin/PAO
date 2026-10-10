import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/location/presentation/address_labels.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// What the customer chose in the address sheet.
sealed class AddressChoice {
  const AddressChoice();
}

/// Use a saved address.
final class UseAddress extends AddressChoice {
  /// Creates the choice.
  const UseAddress(this.id);

  /// The address ID.
  final String id;
}

/// Add a new address.
final class AddAddress extends AddressChoice {
  /// Creates the choice.
  const AddAddress();
}

/// Lets the customer switch the current address or add one (C07).
Future<AddressChoice?> showAddressSheet(
  BuildContext context, {
  required List<Address> addresses,
  required String? currentId,
}) => showPaoSheet<AddressChoice>(
  context,
  title: context.t.homeAddressSheet,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final a in addresses)
        Builder(
          builder: (context) => PaoListRow(
            leading: Icon(addressLabelIcon(a.label)),
            title: addressLabelName(context.t, a.label),
            subtitle: addressLine(a),
            trailing: a.id == currentId
                ? Icon(Icons.check_circle, color: context.pao.accent.primary)
                : const SizedBox.shrink(),
            onTap: () => Navigator.pop(context, UseAddress(a.id)),
          ),
        ),
      const SizedBox(height: PaoSpace.md),
      Builder(
        builder: (context) => PaoButton(
          label: context.t.homeAddAddress,
          icon: Icons.add_location_alt_outlined,
          variant: PaoButtonVariant.soft,
          onPressed: () => Navigator.pop(context, const AddAddress()),
        ),
      ),
    ],
  ),
);
