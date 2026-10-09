import 'package:flutter/material.dart';
import 'package:pao_core/src/state/view_state.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Renders a [ViewState]: skeletons while loading, a retryable error, an empty
/// state when [isEmpty] says so, otherwise [builder].
class ViewStateView<T> extends StatelessWidget {
  /// Creates the view.
  const ViewStateView({
    required this.state,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.empty,
    super.key,
  });

  /// State to render.
  final ViewState<T> state;

  /// Builds the loaded content.
  final Widget Function(BuildContext context, T data) builder;

  /// Retries after a failure.
  final VoidCallback? onRetry;

  /// Whether loaded data counts as empty.
  final bool Function(T data)? isEmpty;

  /// Shown for empty data; a generic empty state when null.
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final l10n = PaoL10n.of(context);
    return switch (state) {
      ViewLoading() => Padding(
        padding: const EdgeInsets.all(PaoSpace.lg),
        child: PaoSkeletonList(semanticLabel: l10n.loading),
      ),
      ViewFailure(:final failure) => PaoErrorState(
        title: l10n.errorTitle,
        message: failureMessage(l10n, failure.code),
        onRetry: onRetry,
        retryLabel: l10n.actionRetry,
      ),
      ViewData(:final data) when isEmpty?.call(data) ?? false =>
        empty ?? PaoEmptyState(title: l10n.emptyTitle),
      ViewData(:final data) => builder(context, data),
    };
  }
}
