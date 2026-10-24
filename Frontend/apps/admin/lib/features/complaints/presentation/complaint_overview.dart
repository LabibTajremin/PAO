import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/complaints/domain/complaints_repository.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// What the complaint is about, who filed it, and links to the booking and
/// both parties the admin may open.
class ComplaintOverview extends StatelessWidget {
  /// Creates the section.
  const ComplaintOverview({
    required this.kase,
    required this.permissions,
    super.key,
  });

  /// The complaint.
  final ComplaintCase kase;

  /// What the admin may open.
  final PermissionService permissions;

  Widget? _profile(
    BuildContext context,
    String label,
    ComplaintReporterRoleEnum role,
    String? id,
  ) {
    final (screen, list) = role == ComplaintReporterRoleEnum.customer
        ? ('A09', Routes.customers)
        : ('A08', Routes.providers);
    if (id == null || !permissions.canSee(screen)) return null;
    return TextButton.icon(
      onPressed: () => context.go(Routes.detail(list, id)),
      icon: const Icon(Icons.person_outline),
      label: Text(label),
    );
  }

  List<Widget> _links(BuildContext context) {
    final t = context.t;
    final c = kase.complaint;
    final other = c.reporterRole == ComplaintReporterRoleEnum.customer
        ? ComplaintReporterRoleEnum.provider
        : ComplaintReporterRoleEnum.customer;
    return [
      if (permissions.canSee('A10'))
        TextButton.icon(
          onPressed: () =>
              context.go(Routes.detail(Routes.bookings, c.bookingId)),
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(t.complaintsOpenBooking),
        ),
      ?_profile(
        context,
        t.complaintsReporterProfile,
        c.reporterRole,
        c.reporterId,
      ),
      ?_profile(context, t.complaintsAgainstProfile, other, c.againstId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = kase.complaint;
    final text = Theme.of(context).textTheme;
    return Section(
      title: c.ticketNumber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PaoSpace.lg,
        children: [
          PaoBadge(
            label: complaintStatusLabel(t, c.status),
            tone: complaintStatusTone(c.status),
          ),
          Wrap(
            spacing: PaoSpace.lg,
            runSpacing: PaoSpace.md,
            children: [
              Fact(t.complaintsReason, complaintReasonLabel(t, c.reason)),
              Fact(t.complaintsReporter, reporterLabel(t, c.reporterRole)),
              Fact(t.complaintsOpened, context.when(c.createdAt)),
              Fact(t.complaintsAssignee, adminLabel(t, c.assigneeId, kase.me)),
            ],
          ),
          Text(t.complaintsDescription, style: text.labelMedium),
          Text(c.description),
          Wrap(spacing: PaoSpace.sm, children: _links(context)),
        ],
      ),
    );
  }
}

/// The photos the reporter attached as evidence.
class ComplaintEvidence extends StatelessWidget {
  /// Creates the section.
  const ComplaintEvidence({required this.photoIds, super.key});

  /// Media IDs of the photos.
  final List<String> photoIds;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Section(
      title: t.complaintsEvidence,
      child: photoIds.isEmpty
          ? Text(t.complaintsNoEvidence)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PaoSpace.sm,
              children: [
                Wrap(
                  spacing: PaoSpace.sm,
                  runSpacing: PaoSpace.sm,
                  children: [
                    for (var i = 1; i <= photoIds.length; i++)
                      PaoChip(
                        label: t.complaintsPhoto(context.count(i)),
                        selected: false,
                        onTap: null,
                      ),
                  ],
                ),
                Text(
                  t.complaintsPhotoPending,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

/// How a resolved complaint was closed.
class ComplaintResolution extends StatelessWidget {
  /// Creates the section.
  const ComplaintResolution({required this.complaint, super.key});

  /// The resolved complaint.
  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final verified = complaint.verified ?? false;
    return Section(
      title: t.complaintsResolutionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PaoSpace.sm,
        children: [
          PaoBadge(
            label: verified ? t.complaintsVerified : t.complaintsNotVerified,
            tone: verified ? PaoTone.danger : PaoTone.neutral,
          ),
          Text(complaint.resolution ?? ''),
          if (complaint.resolvedAt case final at?)
            Text(
              context.when(at),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
