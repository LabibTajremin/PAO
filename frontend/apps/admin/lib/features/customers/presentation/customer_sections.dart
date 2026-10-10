import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/labels.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_admin/shared/ops/status_actions.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// Who the customer is, and the status actions when [onChange] is set.
class CustomerProfileCard extends StatelessWidget {
  /// Creates the section.
  const CustomerProfileCard({
    required this.summary,
    required this.onChange,
    super.key,
  });

  /// The customer.
  final AdminCustomerSummary summary;

  /// Changes the account status; null hides the actions.
  final Future<void> Function(AccountStatusChange change)? onChange;

  StatusPrompts _prompts(BuildContext context) {
    final t = context.t;
    return StatusPrompts(
      name: summary.name,
      banTitle: t.peopleBanTitle(summary.name),
      templates: [
        t.customersReasonAbuse,
        t.customersReasonFake,
        t.customersReasonPayment,
      ],
    );
  }

  List<Widget> _facts(BuildContext context) {
    final t = context.t;
    final s = summary;
    return [
      if (s.phone case final phone?) Fact(t.peoplePhone, phone),
      Fact(t.customersBookings, context.count(s.bookings)),
      Fact(
        t.peopleRating,
        s.rating == null ? t.peopleNoRating : context.rating(s.rating!),
      ),
      Fact(t.peopleJoined, context.when(s.createdAt, 'd MMM y')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = summary;
    return Section(
      title: t.customersProfile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PaoSpace.lg,
        children: [
          Row(
            spacing: PaoSpace.md,
            children: [
              PaoAvatar(name: s.name),
              Expanded(
                child: Text(
                  s.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              PaoBadge(
                label: accountStatusLabel(t, s.status),
                tone: accountStatusTone(s.status),
              ),
            ],
          ),
          Wrap(
            spacing: PaoSpace.lg,
            runSpacing: PaoSpace.md,
            children: _facts(context),
          ),
          if (onChange case final change?)
            AccountStatusActions(
              status: s.status,
              prompts: _prompts(context),
              onChange: change,
            ),
        ],
      ),
    );
  }
}

/// Complaints the customer filed or that were filed about them; a row opens
/// the complaint when [canOpen].
class CustomerComplaints extends StatelessWidget {
  /// Creates the section.
  const CustomerComplaints({
    required this.complaints,
    required this.canOpen,
    super.key,
  });

  /// Newest first.
  final List<Complaint> complaints;

  /// Whether the admin may open the complaints queue (A11).
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Section(
      title: t.customersComplaints,
      child: complaints.isEmpty
          ? Text(t.customersNoComplaints)
          : Column(
              children: [
                for (final c in complaints)
                  PaoListRow(
                    title:
                        '${c.ticketNumber} · '
                        '${complaintReasonLabel(t, c.reason)}',
                    subtitle: context.when(c.createdAt),
                    trailing: PaoBadge(
                      label: complaintStatusLabel(t, c.status),
                      tone: complaintStatusTone(c.status),
                    ),
                    onTap: canOpen
                        ? () =>
                              context.go(Routes.detail(Routes.complaints, c.id))
                        : null,
                  ),
              ],
            ),
    );
  }
}
