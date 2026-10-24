import 'package:flutter/material.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/billing/domain/billing_repository.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';

/// One console section in the navigation.
class NavEntry {
  /// Creates an entry; with [permission] that permission shows it instead of
  /// the screen ID.
  const NavEntry(
    this.screen,
    this.path,
    this.icon,
    this.label, {
    this.permission,
  });

  /// Screen ID that must be permitted for the entry to show.
  final String screen;

  /// Permission that shows the entry, for sections without a screen ID.
  final String? permission;

  /// Where the entry goes.
  final String path;

  /// Icon.
  final IconData icon;

  /// Label in the current language.
  final String Function(AdminL10n t) label;
}

/// Console sections in menu order (PRD §8.3).
final List<NavEntry> navEntries = [
  NavEntry(
    'A02',
    Routes.dashboard,
    Icons.space_dashboard_outlined,
    (t) => t.navDashboard,
  ),
  NavEntry(
    'A05',
    Routes.verification,
    Icons.fact_check_outlined,
    (t) => t.navVerification,
  ),
  NavEntry(
    'A07',
    Routes.level2,
    Icons.workspace_premium_outlined,
    (t) => t.navLevel2,
  ),
  NavEntry('A03', Routes.catalog, Icons.category_outlined, (t) => t.navCatalog),
  NavEntry(
    'A08',
    Routes.providers,
    Icons.engineering_outlined,
    (t) => t.navProviders,
  ),
  NavEntry(
    'A09',
    Routes.customers,
    Icons.people_outline,
    (t) => t.navCustomers,
  ),
  NavEntry(
    'A10',
    Routes.bookings,
    Icons.receipt_long_outlined,
    (t) => t.navBookings,
  ),
  NavEntry(
    'A11',
    Routes.complaints,
    Icons.report_outlined,
    (t) => t.navComplaints,
  ),
  // Billing came after the screen catalogue (ADR-0035), so its permission
  // shows it.
  NavEntry(
    '',
    Routes.payments,
    Icons.payments_outlined,
    (t) => t.navPayments,
    permission: billingPermission,
  ),
  NavEntry(
    'A12',
    Routes.settings,
    Icons.settings_outlined,
    (t) => t.navSettings,
  ),
];
