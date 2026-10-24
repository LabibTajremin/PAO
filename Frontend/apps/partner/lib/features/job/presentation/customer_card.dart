import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart' show Booking;
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Customer name, address, call and directions (P-07); the phone and exact
/// address arrive only after acceptance (PRD §5 step 6).
class CustomerCard extends StatelessWidget {
  /// Creates the card.
  const CustomerCard({
    required this.booking,
    required this.launcher,
    super.key,
  });

  /// The job.
  final Booking booking;

  /// Maps and dialler.
  final Launcher launcher;

  @override
  Widget build(BuildContext context) {
    final customer = booking.customer;
    final address = booking.address;
    final lines = [address.line1, address.line2, address.area].nonNulls;
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaoListRow(
            leading: PaoAvatar(name: customer?.name ?? '?', size: 40),
            title: customer?.name ?? context.t.jobCustomer,
            subtitle: lines.join(', '),
          ),
          const SizedBox(height: PaoSpace.md),
          Row(children: _buttons(context)),
        ],
      ),
    );
  }

  List<Widget> _buttons(BuildContext context) {
    final phone = booking.customer?.phone;
    final at = booking.address.location;
    return [
      if (at != null)
        Expanded(
          child: PaoButton(
            label: context.t.jobActionNavigate,
            icon: Icons.directions_outlined,
            variant: PaoButtonVariant.soft,
            onPressed: () => launcher.directions(at.lat, at.lng),
          ),
        ),
      if (at != null && phone != null) const SizedBox(width: PaoSpace.sm),
      if (phone != null)
        Expanded(
          child: PaoButton(
            label: context.t.jobActionCall,
            icon: Icons.call_outlined,
            variant: PaoButtonVariant.outline,
            onPressed: () => launcher.call(phone),
          ),
        ),
    ];
  }
}
