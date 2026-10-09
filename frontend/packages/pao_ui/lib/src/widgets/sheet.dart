import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// Shows [child] in a rounded bottom sheet with a drag handle and [title].
Future<T?> showPaoSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: PaoColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(PaoRadius.xl)),
  ),
  builder: (context) => PaoSheet(title: title, child: child),
);

/// The body of a PAO bottom sheet.
class PaoSheet extends StatelessWidget {
  /// Creates a sheet body.
  const PaoSheet({required this.title, required this.child, super.key});

  /// Heading.
  final String title;

  /// Content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          PaoSpace.xl,
          PaoSpace.md,
          PaoSpace.xl,
          PaoSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PaoColors.border,
                  borderRadius: BorderRadius.circular(PaoRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: PaoSpace.lg),
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: PaoSpace.lg),
            child,
          ],
        ),
      ),
    );
  }
}
