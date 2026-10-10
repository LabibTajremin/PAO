import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// Opens [child] in a panel sliding in from the right, over the list it
/// belongs to; resolves with what the panel pops.
Future<T?> showDetailDrawer<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  pageBuilder: (_, _, _) => Align(
    alignment: Alignment.centerRight,
    child: DetailPanel(title: title, child: child),
  ),
  transitionBuilder: (_, animation, _, panel) => SlideTransition(
    position: Tween(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(animation),
    child: panel,
  ),
);

/// A titled, scrolling side panel with a close button.
class DetailPanel extends StatelessWidget {
  /// Creates the panel.
  const DetailPanel({required this.title, required this.child, super.key});

  /// Heading.
  final String title;

  /// Content.
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: PaoColors.surface,
    child: SizedBox(
      width: 480,
      height: double.infinity,
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: Theme.of(context).textTheme.titleLarge),
            trailing: CloseButton(onPressed: () => Navigator.pop(context)),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PaoSpace.lg),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );
}
