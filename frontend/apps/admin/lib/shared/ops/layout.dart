import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// Content width from which detail screens put their sections side by side.
const twoColumnWidth = 900.0;

/// A detail screen: a link back to its list above the record, which shows
/// skeletons, a retryable error or the loaded [builder] content.
class DetailFrame<T> extends StatelessWidget {
  /// Creates the frame.
  const DetailFrame({
    required this.back,
    required this.state,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  /// The link back to the list.
  final BackLink back;

  /// The record being shown.
  final ViewState<T> state;

  /// Loads the record again after a failure.
  final VoidCallback onRetry;

  /// Builds the loaded record.
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(PaoSpace.lg),
    children: [
      Align(alignment: Alignment.centerLeft, child: back),
      const SizedBox(height: PaoSpace.md),
      ViewStateView<T>(state: state, onRetry: onRetry, builder: builder),
    ],
  );
}

/// "← All providers": goes back to a list screen.
class BackLink extends StatelessWidget {
  /// Creates the link to [to].
  const BackLink({required this.label, required this.to, super.key});

  /// Link text.
  final String label;

  /// Where it goes.
  final String to;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.go(to),
    icon: const Icon(Icons.arrow_back),
    label: Text(label),
  );
}

/// Lays out [first] and [second] side by side on wide screens and stacked on
/// narrow ones.
class SplitColumns extends StatelessWidget {
  /// Creates the layout.
  const SplitColumns({required this.first, required this.second, super.key});

  /// Main sections.
  final List<Widget> first;

  /// Secondary sections.
  final List<Widget> second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      Widget column(List<Widget> children) =>
          Column(spacing: PaoSpace.lg, children: children);
      if (box.maxWidth < twoColumnWidth) return column([...first, ...second]);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PaoSpace.lg,
        children: [
          Expanded(flex: 3, child: column(first)),
          Expanded(flex: 2, child: column(second)),
        ],
      );
    },
  );
}

/// A titled card on a detail screen.
class Section extends StatelessWidget {
  /// Creates the section.
  const Section({required this.title, required this.child, super.key});

  /// Heading.
  final String title;

  /// Content.
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: PaoSpace.md),
          child,
        ],
      ),
    ),
  );
}

/// A labelled value, e.g. "Rating 4.8", laid out in a wrapping grid.
class Fact extends StatelessWidget {
  /// Creates the fact.
  const Fact(this.label, this.value, {super.key});

  /// What the value is.
  final String label;

  /// The value.
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelMedium!.copyWith(color: PaoColors.textSecondary),
          ),
          Text(value, style: text.bodyLarge),
        ],
      ),
    );
  }
}

/// A heading above a list screen.
class ListHeading extends StatelessWidget {
  /// Creates the heading.
  const ListHeading(this.title, {this.trailing, super.key});

  /// Heading text.
  final String title;

  /// Shown at the end of the line, e.g. a refresh note.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PaoSpace.lg),
    child: Wrap(
      spacing: PaoSpace.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ?trailing,
      ],
    ),
  );
}

/// A status badge in a table cell, kept at its own width.
class StatusCell extends StatelessWidget {
  /// Creates the cell.
  const StatusCell({required this.label, required this.tone, super.key});

  /// Badge text.
  final String label;

  /// Badge colour.
  final PaoTone tone;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: PaoBadge(label: label, tone: tone),
  );
}
