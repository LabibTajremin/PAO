import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// The title row of a console screen with its actions on the right; it wraps
/// below the title on narrow screens.
class PageHeader extends StatelessWidget {
  /// Creates the header.
  const PageHeader({
    required this.title,
    this.leading,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  /// Screen title.
  final String title;

  /// E.g. a back button.
  final Widget? leading;

  /// A line under the title.
  final Widget? subtitle;

  /// Buttons on the right.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PaoSpace.lg,
      PaoSpace.lg,
      PaoSpace.lg,
      0,
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: PaoSpace.md,
      runSpacing: PaoSpace.md,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?leading,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                ?subtitle,
              ],
            ),
          ],
        ),
        Wrap(spacing: PaoSpace.sm, runSpacing: PaoSpace.sm, children: actions),
      ],
    ),
  );
}
