import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/location/presentation/address_labels.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The current address; tapping it opens the address sheet.
class AddressHeader extends StatelessWidget {
  /// Creates the header for [address].
  const AddressHeader({required this.address, required this.onTap, super.key});

  /// The current address, if any.
  final Address? address;

  /// Opens the address sheet.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = address;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.location_on, color: context.pao.accent.primary),
          const SizedBox(width: PaoSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t.homeAddressTitle, style: text.bodySmall),
                Text(
                  a == null ? context.t.homeNoAddress : addressLine(a),
                  style: text.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_more),
        ],
      ),
    );
  }
}

/// A search field look-alike that opens search (C08).
class SearchBarButton extends StatelessWidget {
  /// Creates the bar.
  const SearchBarButton({required this.onTap, super.key});

  /// Opens search.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PaoCard(
    onTap: onTap,
    child: Row(
      children: [
        const Icon(Icons.search, color: PaoColors.textSecondary),
        const SizedBox(width: PaoSpace.sm),
        Text(
          context.t.homeSearchHint,
          style: const TextStyle(color: PaoColors.textSecondary),
        ),
      ],
    ),
  );
}

/// The running booking; tapping it opens its tracker.
class ActiveBookingBanner extends StatelessWidget {
  /// Creates the banner for [booking].
  const ActiveBookingBanner({
    required this.booking,
    required this.onTap,
    super.key,
  });

  /// The running booking.
  final BookingSummary booking;

  /// Opens the tracker.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PaoCard(
    highlighted: true,
    onTap: onTap,
    child: Row(
      children: [
        const PaoIconTile(icon: Icons.timelapse),
        const SizedBox(width: PaoSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.local(booking.serviceName),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(activeStatusText(context.t, booking.status)),
            ],
          ),
        ),
        Text(context.t.homeActiveOpen),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

/// What the running booking is doing.
String activeStatusText(CustomerL10n t, BookingStatus status) =>
    switch (status) {
      BookingStatus.requested => t.homeStatusRequested,
      BookingStatus.accepted => t.homeStatusAccepted,
      BookingStatus.onTheWay => t.homeStatusOnTheWay,
      BookingStatus.arrived => t.homeStatusArrived,
      _ => t.homeStatusInProgress,
    };

/// PAO does not work at the current address yet (C35).
class AreaNotCovered extends StatelessWidget {
  /// Creates the view; [onChange] opens the address sheet.
  const AreaNotCovered({required this.onChange, super.key});

  /// Opens the address sheet.
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => PaoMessageState(
    icon: Icons.wrong_location_outlined,
    title: context.t.locNotCoveredTitle,
    message: context.t.homeNotCoveredBody,
    action: PaoButton(
      label: context.t.homeChangeAddress,
      onPressed: onChange,
      expand: false,
    ),
  );
}
