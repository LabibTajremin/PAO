import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_partner/features/jobs/presentation/paged_cubit.dart';
import 'package:pao_partner/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// A scrolling list over the nearest [PagedCubit]: skeletons, a retryable
/// error or [empty] before the first rows, then the rows and "load more".
class PagedView<T> extends StatelessWidget {
  /// Creates the list; [header] scrolls above the rows.
  const PagedView({
    required this.itemBuilder,
    required this.empty,
    this.header = const [],
    super.key,
  });

  /// Builds one row.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Shown when the list has no rows.
  final Widget empty;

  /// Widgets above the rows.
  final List<Widget> header;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PagedCubit<T>, PagedState<T>>(
        builder: (context, s) => ListView(
          padding: const EdgeInsets.all(PaoSpace.lg),
          children: [
            ...header,
            if (s.items.isEmpty)
              _first(context, s)
            else ...[
              for (final item in s.items) itemBuilder(context, item),
              _footer(context, s),
            ],
          ],
        ),
      );

  Widget _first(BuildContext context, PagedState<T> s) {
    final common = context.common;
    if (s.loading) return PaoSkeletonList(semanticLabel: common.loading);
    if (s.failure == null) return empty;
    return PaoErrorState(
      title: context.common.errorTitle,
      message: context.failureText(s.failure)!,
      onRetry: context.read<PagedCubit<T>>().load,
      retryLabel: context.common.actionRetry,
    );
  }

  Widget _footer(BuildContext context, PagedState<T> s) {
    if (s.loading) {
      return const Padding(
        padding: EdgeInsets.all(PaoSpace.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (s.next == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: PaoSpace.md),
      child: Column(
        children: [
          if (s.failure != null)
            Text(
              context.failureText(s.failure)!,
              style: const TextStyle(color: PaoColors.danger),
            ),
          PaoButton(
            label: context.t.jobsLoadMore,
            variant: PaoButtonVariant.soft,
            onPressed: context.read<PagedCubit<T>>().more,
          ),
        ],
      ),
    );
  }
}
