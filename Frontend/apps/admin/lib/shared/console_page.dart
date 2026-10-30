import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// A console screen: a heading with [actions] on the right (wrapping below it
/// on narrow screens), an optional [subtitle], and [child] filling the rest.
class ConsolePage extends StatelessWidget {
  /// Creates the page.
  const ConsolePage({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.leading,
    super.key,
  });

  /// Heading.
  final String title;

  /// Line under the heading, e.g. when the data was generated.
  final String? subtitle;

  /// Buttons beside the heading.
  final List<Widget> actions;

  /// Widget before the heading, such as a back button.
  final Widget? leading;

  /// Content below the heading.
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PaoSpace.xxl,
          PaoSpace.xxl,
          PaoSpace.xxl,
          PaoSpace.md,
        ),
        child: Wrap(
          spacing: PaoSpace.md,
          runSpacing: PaoSpace.md,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [?leading, _heading(context)],
            ),
            Wrap(spacing: PaoSpace.sm, children: actions),
          ],
        ),
      ),
      Expanded(child: child),
    ],
  );

  Widget _heading(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.headlineSmall),
        if (subtitle != null)
          Text(
            subtitle!,
            style: text.bodySmall!.copyWith(color: PaoColors.textSecondary),
          ),
      ],
    );
  }
}

/// Confirms a finished action, such as a save, at the bottom of the screen.
void showDone(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
