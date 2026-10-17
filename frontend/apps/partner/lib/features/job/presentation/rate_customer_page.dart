import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show ReviewTag;
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_partner/features/job/data/api_job_repository.dart';
import 'package:pao_partner/features/job/presentation/rate_cubit.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Stars, tags and a comment about the customer (M21, P-09).
class RateCustomerPage extends StatefulWidget {
  /// Creates the page.
  const RateCustomerPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  State<RateCustomerPage> createState() => _RateCustomerPageState();
}

class _RateCustomerPageState extends State<RateCustomerPage> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        RateCubit(ApiJobRepository(widget.services.api), widget.bookingId),
    child: BlocConsumer<RateCubit, RateState>(
      listenWhen: (_, s) => s.done,
      listener: (context, _) => context.go(Routes.home),
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.jobRateTitle),
        body: _form(context, s),
      ),
    ),
  );

  Widget _form(BuildContext context, RateState s) {
    final cubit = context.read<RateCubit>();
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        Text(context.t.jobRateQuestion),
        const SizedBox(height: PaoSpace.lg),
        Center(
          child: PaoRatingStars(
            rating: s.stars.toDouble(),
            semanticLabel: context.t.jobRateStars(s.stars),
            onChanged: cubit.rate,
            size: 36,
          ),
        ),
        const SizedBox(height: PaoSpace.lg),
        _tags(context, s),
        const SizedBox(height: PaoSpace.lg),
        PaoTextField(
          label: context.t.jobRateComment,
          controller: _comment,
          maxLines: 3,
        ),
        if (s.failure != null)
          Text(
            context.failureText(s.failure)!,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: context.t.jobRateSubmit,
          loading: s.busy,
          onPressed: s.stars == 0 ? null : () => cubit.submit(_comment.text),
        ),
        PaoButton(
          label: context.t.jobRateSkip,
          variant: PaoButtonVariant.ghost,
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }

  Widget _tags(BuildContext context, RateState s) => Wrap(
    spacing: PaoSpace.sm,
    runSpacing: PaoSpace.sm,
    children: [
      for (final tag in RateCubit.tags)
        PaoChip(
          label: _tagText(context.t, tag),
          selected: s.tags.contains(tag),
          onTap: () => context.read<RateCubit>().toggle(tag),
        ),
    ],
  );
}

String _tagText(PartnerL10n t, ReviewTag tag) => switch (tag) {
  ReviewTag.polite => t.jobTagPolite,
  ReviewTag.clearInstructions => t.jobTagClearInstructions,
  ReviewTag.paidPromptly => t.jobTagPaidPromptly,
  ReviewTag.safePlace => t.jobTagSafePlace,
  ReviewTag.rude => t.jobTagRude,
  ReviewTag.unclearInstructions => t.jobTagUnclearInstructions,
  _ => t.jobTagUnsafePlace,
};
