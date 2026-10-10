import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/profile/data/api_profile_repository.dart';
import 'package:pao_partner/features/profile/presentation/profile_labels.dart';
import 'package:pao_partner/shared/formats.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// How long before expiry a document is flagged for renewal (P-11).
const renewalWarning = Duration(days: 30);

/// Documents, their review status and expiry (M31).
class DocumentsPage extends StatelessWidget {
  /// Creates the page.
  const DocumentsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoadCubit<VerificationStatus>(
      ApiProfileRepository(services.api).verification,
    ).loading(),
    child: Scaffold(
      appBar: PaoAppBar(title: context.t.profDocumentsTitle),
      body:
          BlocBuilder<
            LoadCubit<VerificationStatus>,
            ViewState<VerificationStatus>
          >(
            builder: (context, state) => ViewStateView<VerificationStatus>(
              state: state,
              onRetry: context.read<LoadCubit<VerificationStatus>>().load,
              isEmpty: (status) => status.items.isEmpty,
              empty: PaoEmptyState(title: context.t.profDocumentsEmpty),
              builder: (_, status) => ListView(
                padding: const EdgeInsets.all(PaoSpace.lg),
                children: [
                  for (final item in status.items)
                    _Document(item: item, now: services.now()),
                  const SizedBox(height: PaoSpace.xl),
                  PaoButton(
                    label: context.t.profDocumentsUpdate,
                    variant: PaoButtonVariant.soft,
                    onPressed: () => context.push(Routes.verification),
                  ),
                ],
              ),
            ),
          ),
    ),
  );
}

class _Document extends StatelessWidget {
  const _Document({required this.item, required this.now});

  final VerificationItem item;
  final DateTime now;

  String? _expiry(BuildContext context) {
    final at = item.expiresAt;
    if (at == null) return null;
    final t = context.t;
    final date = context.when(at, 'd MMM y');
    if (at.isBefore(now)) return t.profExpired(date);
    final soon = at.difference(now) < renewalWarning;
    return soon ? t.profExpiresSoon(date) : t.profValidUntil(date);
  }

  @override
  Widget build(BuildContext context) {
    final lines = [?_expiry(context), ?item.rejectionReason];
    return PaoListRow(
      title: itemLabel(context.t, item.type),
      subtitle: lines.isEmpty ? null : lines.join('\n'),
      trailing: PaoBadge(
        label: itemStatusLabel(context.t, item.status),
        tone: itemStatusTone(item.status),
      ),
    );
  }
}
