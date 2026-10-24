import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/dashboard/presentation/booking_bars.dart';
import 'package:pao_admin/features/dashboard/presentation/breakdown_card.dart';
import 'package:pao_admin/features/dashboard/presentation/dashboard_labels.dart';
import 'package:pao_admin/features/dashboard/presentation/kpi_tile.dart';
import 'package:pao_admin/shared/console_formats.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Width from which the two provider breakdowns sit side by side.
const _twoColumns = 720.0;

/// The loaded dashboard: counts on top, then bookings per day and the
/// provider breakdowns.
class DashboardBody extends StatelessWidget {
  /// Creates the body.
  const DashboardBody({
    required this.data,
    required this.permissions,
    super.key,
  });

  /// Figures to show.
  final Dashboard data;

  /// Decides which counts open their queue.
  final PermissionService permissions;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      PaoSpace.xxl,
      PaoSpace.sm,
      PaoSpace.xxl,
      PaoSpace.xxl,
    ),
    children: [
      _kpis(context),
      const SizedBox(height: PaoSpace.xxl),
      PaoCard(child: BookingBars(days: data.bookingsPerDay)),
      const SizedBox(height: PaoSpace.xxl),
      LayoutBuilder(builder: _breakdowns),
    ],
  );

  Widget _kpis(BuildContext context) {
    final t = context.t;
    final bookings = data.bookingsPerDay.fold(0, (sum, d) => sum + d.total);
    return Wrap(
      spacing: PaoSpace.lg,
      runSpacing: PaoSpace.lg,
      children: [
        KpiTile(
          icon: Icons.fact_check_outlined,
          label: t.dashPendingVerifications,
          value: context.count(data.pendingVerifications),
          onTap: _open(context, 'A05', Routes.verification),
        ),
        KpiTile(
          icon: Icons.report_outlined,
          label: t.dashOpenComplaints,
          value: context.count(data.openComplaints),
          onTap: _open(context, 'A11', Routes.complaints),
        ),
        KpiTile(
          icon: Icons.task_alt,
          label: t.dashCompletionRate,
          value: context.percent(data.completionRate),
        ),
        KpiTile(
          icon: Icons.receipt_long_outlined,
          label: t.dashBookings,
          value: context.count(bookings),
        ),
        KpiTile(
          icon: Icons.engineering_outlined,
          label: t.dashActiveProviders,
          value: context.count(data.providersByStatus['active'] ?? 0),
        ),
      ],
    );
  }

  Widget _breakdowns(BuildContext context, BoxConstraints box) {
    final width = box.maxWidth >= _twoColumns
        ? (box.maxWidth - PaoSpace.lg) / 2
        : box.maxWidth;
    return Wrap(
      spacing: PaoSpace.lg,
      runSpacing: PaoSpace.lg,
      children: [
        SizedBox(
          width: width,
          child: BreakdownCard(
            title: context.t.dashProvidersByStatus,
            counts: data.providersByStatus,
            label: (key) => statusLabel(context.t, key),
          ),
        ),
        SizedBox(
          width: width,
          child: BreakdownCard(
            title: context.t.dashProvidersByLevel,
            counts: data.providersByLevel,
            label: (key) => levelLabel(context.t, key),
          ),
        ),
      ],
    );
  }

  VoidCallback? _open(BuildContext context, String screen, String path) =>
      permissions.canSee(screen) ? () => context.go(path) : null;
}
