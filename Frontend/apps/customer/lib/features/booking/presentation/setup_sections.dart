import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Address, AddressLabel, Timing;
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/booking/presentation/address_sheet.dart';
import 'package:pao_customer/features/booking/presentation/schedule_picker.dart';
import 'package:pao_customer/features/booking/presentation/setup_cubit.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A section heading on the set-up form.
class SectionTitle extends StatelessWidget {
  /// Creates the heading.
  const SectionTitle(this.text, {super.key});

  /// Heading text.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PaoSpace.sm),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    ),
  );
}

/// ASAP or a scheduled slot (C45, C12); a duration hire is always scheduled.
class WhenSection extends StatelessWidget {
  /// Creates the section.
  const WhenSection({
    required this.state,
    required this.now,
    required this.fixed,
    super.key,
  });

  /// The form.
  final SetupState state;

  /// The app clock.
  final DateTime Function() now;

  /// Only a scheduled start is allowed.
  final bool fixed;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cubit = context.read<SetupCubit>();
    final at = state.at;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(t.bookingWhenTitle),
        if (!fixed)
          PaoSegmented<Timing>(
            segments: {
              Timing.asap: t.bookingAsap,
              Timing.scheduled: t.bookingScheduled,
            },
            selected: state.timing,
            onChanged: cubit.timing,
          ),
        if (state.timing == Timing.scheduled)
          PaoListRow(
            leading: const Icon(Icons.event_outlined),
            title: at == null
                ? t.bookingPickTime
                : context.when(at, 'EEE d MMM y, h:mm a'),
            onTap: () async {
              final picked = await pickSchedule(context, now(), at);
              if (picked != null) cubit.schedule(picked);
            },
          ),
        if (state.invalidTime)
          Text(
            t.bookingTimeInvalid,
            style: const TextStyle(color: PaoColors.danger),
          ),
      ],
    );
  }
}

/// The service address with a way to change or add one (C46).
class WhereSection extends StatelessWidget {
  /// Creates the section.
  const WhereSection({required this.state, super.key});

  /// The form.
  final SetupState state;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final addresses = state.options!.addresses;
    final chosen = addresses.where((a) => a.id == state.addressId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(t.bookingWhereTitle),
        if (chosen == null) ...[
          Text(t.bookingNoAddress),
          const SizedBox(height: PaoSpace.sm),
          PaoButton(
            label: t.bookingAddAddress,
            icon: Icons.add_location_alt_outlined,
            variant: PaoButtonVariant.outline,
            onPressed: () => _add(context),
          ),
        ] else
          PaoListRow(
            leading: const Icon(Icons.place_outlined),
            title: addressLabel(context, chosen),
            subtitle: addressLine(chosen),
            trailing: Text(t.bookingChange),
            onTap: () => _choose(context),
          ),
      ],
    );
  }

  Future<void> _choose(BuildContext context) async {
    final cubit = context.read<SetupCubit>();
    final add = await showAddressSheet(context, cubit);
    if (add && context.mounted) await _add(context);
  }

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<SetupCubit>();
    await context.push(Routes.addressNew);
    await cubit.reloadAddresses();
  }
}

/// Payment is cash to the provider after the job (D4).
class PaymentSection extends StatelessWidget {
  /// Creates the section.
  const PaymentSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionTitle(context.t.bookingPaymentTitle),
      PaoListRow(
        leading: const Icon(Icons.payments_outlined),
        title: context.t.bookingCash,
        subtitle: context.t.bookingCashBody,
      ),
    ],
  );
}

/// The address's label: Home, Office or Other.
String addressLabel(BuildContext context, Address a) => switch (a.label) {
  AddressLabel.home => context.t.bookingLabelHome,
  AddressLabel.office => context.t.bookingLabelOffice,
  _ => context.t.bookingLabelOther,
};

/// The address's street lines and area on one line.
String addressLine(Address a) =>
    [a.line1, a.line2, a.area].nonNulls.where((s) => s.isNotEmpty).join(', ');
