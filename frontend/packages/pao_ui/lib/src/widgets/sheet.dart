import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/shape.dart';

/// Shows [child] in a leaf-topped bottom sheet with a drag handle and [title].
Future<T?> showPaoSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.pao.card,
  shape: const RoundedRectangleBorder(borderRadius: PaoShape.sheet),
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
          PaoSpace.xxl,
          PaoSpace.md,
          PaoSpace.xxl,
          PaoSpace.xxl + MediaQuery.viewInsetsOf(context).bottom,
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
                  color: context.pao.hairline,
                  borderRadius: BorderRadius.circular(PaoRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: PaoSpace.xl),
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
