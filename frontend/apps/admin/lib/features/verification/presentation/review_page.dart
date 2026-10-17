import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/verification/domain/verification_repository.dart';
import 'package:pao_admin/features/verification/presentation/document_viewer.dart';
import 'package:pao_admin/features/verification/presentation/labels.dart';
import 'package:pao_admin/features/verification/presentation/review_body.dart';
import 'package:pao_admin/features/verification/presentation/review_cubit.dart';
import 'package:pao_admin/features/verification/presentation/review_header.dart';
import 'package:pao_admin/shared/confirm_reason.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Reviews one provider's documents (A06). Keys: A approves and R rejects
/// the focused item, N opens the next provider, ↑/↓ move the focus.
class ReviewPage extends StatelessWidget {
  /// Creates the page for [providerId].
  const ReviewPage({
    required this.repo,
    required this.providerId,
    required this.permissions,
    this.image = networkDocument,
    super.key,
  });

  /// Where the review comes from.
  final VerificationRepository repo;

  /// Provider under review.
  final String providerId;

  /// What the admin may do.
  final PermissionService permissions;

  /// Builds document pictures.
  final DocumentImageBuilder image;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = ReviewCubit(repo, providerId);
      unawaited(cubit.load());
      return cubit;
    },
    child: _ReviewView(page: this),
  );
}

class _ReviewView extends StatefulWidget {
  const _ReviewView({required this.page});

  final ReviewPage page;

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  // Holds the keyboard focus for the shortcuts; dialogs and taps take it
  // away, so it is asked back after each of them.
  final _keys = FocusNode(debugLabel: 'review shortcuts');

  ReviewPage get page => widget.page;

  bool get _canDecide => page.permissions.can(reviewPermission);

  @override
  void dispose() {
    _keys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ReviewCubit, ReviewState>(
    listenWhen: (before, now) =>
        now.outcome != null ||
        (now.failure != null && before.failure != now.failure),
    listener: _react,
    builder: (context, state) => CallbackShortcuts(
      bindings: _bindings(state),
      child: Focus(
        focusNode: _keys,
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReviewHeader(
              review: state.review,
              onNext: state.busy ? null : context.read<ReviewCubit>().next,
            ),
            Expanded(child: _body(state)),
          ],
        ),
      ),
    ),
  );

  void _react(BuildContext context, ReviewState state) {
    if (state.outcome case NextProvider(:final id?)) {
      return context.go(Routes.reviewOf(id));
    }
    final t = context.t;
    final message = switch (state.outcome) {
      Decided(:final level) => t.verifyDecided(levelLabel(t, level)),
      NextProvider() => t.verifyQueueDone,
      null => context.failureText(state.failure)!,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Map<ShortcutActivator, VoidCallback> _bindings(ReviewState state) {
    final cubit = context.read<ReviewCubit>();
    final focused = state.focused;
    return {
      const SingleActivator(LogicalKeyboardKey.keyN): cubit.next,
      const SingleActivator(LogicalKeyboardKey.arrowDown): () => cubit.move(1),
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => cubit.move(-1),
      if (_canDecide && focused != null && !state.busy) ...{
        const SingleActivator(LogicalKeyboardKey.keyA): () =>
            cubit.approve(focused),
        const SingleActivator(LogicalKeyboardKey.keyR): () => _reject(focused),
      },
    };
  }

  Widget _body(ReviewState state) {
    final cubit = context.read<ReviewCubit>();
    return ViewStateView<VerificationReview>(
      state: state.view,
      onRetry: cubit.load,
      builder: (context, review) => ReviewBody(
        state: state,
        handlers: ReviewHandlers(
          onFocus: (type) {
            _keys.requestFocus();
            cubit.focus(type);
          },
          onApprove: _canDecide ? cubit.approve : null,
          onReject: _canDecide ? _reject : null,
          onDocuments: page.permissions.can(docsPermission)
              ? (item) => _documents(review, item)
              : null,
        ),
      ),
    );
  }

  Future<void> _reject(ItemType type) async {
    final cubit = context.read<ReviewCubit>();
    final t = context.t;
    final reason = await confirmWithReason(
      context,
      title: t.verifyRejectTitle(itemLabel(t, type)),
      confirmLabel: t.verifyReject,
      templates: rejectTemplates(t),
    );
    _keys.requestFocus();
    if (reason != null) await cubit.reject(type, reason);
  }

  Future<void> _documents(VerificationReview review, ReviewItem item) async {
    final t = context.t;
    await showDialog<void>(
      context: context,
      builder: (_) => DocumentsDialog(
        title: itemLabel(t, item.type),
        repo: page.repo,
        image: page.image,
        documents: [
          for (final d in documentsToCompare(review, item))
            (mediaId: d.mediaId, label: documentLabel(t, d.kind)),
        ],
      ),
    );
    _keys.requestFocus();
  }
}
