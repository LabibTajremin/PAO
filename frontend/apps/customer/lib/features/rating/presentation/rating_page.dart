import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart' show Booking;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/rating/data/api_rating_repository.dart';
import 'package:pao_customer/features/rating/presentation/rating_cubit.dart';
import 'package:pao_customer/features/rating/presentation/rating_views.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Stars, tags and a comment about the provider (C17), then thanks (C55).
class RatingPage extends StatefulWidget {
  /// Creates the page.
  const RatingPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        RatingCubit(ApiRatingRepository(widget.services.api), widget.bookingId)
          ..load().ignore(),
    child: BlocBuilder<RatingCubit, RatingState>(
      builder: (context, s) => Scaffold(
        appBar: PaoAppBar(title: context.t.ratingTitle),
        body: ViewStateView<Booking>(
          state: s.view,
          onRetry: context.read<RatingCubit>().load,
          builder: (_, b) => s.done ? const ThanksView() : _form(context, s, b),
        ),
      ),
    ),
  );

  Widget _commentField(BuildContext context) => PaoTextField(
    label: context.t.ratingComment,
    controller: _comment,
    maxLines: 3,
    inputFormatters: [LengthLimitingTextInputFormatter(500)],
  );

  Widget _form(BuildContext context, RatingState s, Booking b) {
    final t = context.t;
    final cubit = context.read<RatingCubit>();
    return ListView(
      padding: const EdgeInsets.all(PaoSpace.xl),
      children: [
        RatingHeader(name: b.provider?.name ?? ''),
        const SizedBox(height: PaoSpace.lg),
        Center(
          child: PaoRatingStars(
            rating: s.stars.toDouble(),
            semanticLabel: context.common.ratingLabel('${s.stars}'),
            onChanged: cubit.rate,
            size: 40,
          ),
        ),
        const SizedBox(height: PaoSpace.lg),
        RatingTags(selected: s.tags, onToggle: cubit.toggle),
        const SizedBox(height: PaoSpace.lg),
        _commentField(context),
        if (s.failure != null)
          Text(
            context.failureText(s.failure)!,
            style: const TextStyle(color: PaoColors.danger),
          ),
        const SizedBox(height: PaoSpace.xl),
        PaoButton(
          label: t.ratingSubmit,
          loading: s.busy,
          onPressed: s.stars == 0 ? null : () => cubit.submit(_comment.text),
        ),
        PaoButton(
          label: t.ratingSkip,
          variant: PaoButtonVariant.ghost,
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }
}
