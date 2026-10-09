import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// A grey placeholder block shown while content loads. It is static on purpose:
/// shimmer animations cost battery on low-end phones (PRD §11).
class PaoSkeleton extends StatelessWidget {
  /// Creates a block of [height]; [width] defaults to the available width.
  const PaoSkeleton({
    this.height = 16,
    this.width,
    this.radius = PaoRadius.sm,
    super.key,
  });

  /// Block height.
  final double height;

  /// Block width.
  final double? width;

  /// Corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: PaoColors.border,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// A card-shaped list of skeleton lines with one "Loading" label for screen
/// readers.
class PaoSkeletonList extends StatelessWidget {
  /// Creates [count] placeholder rows.
  const PaoSkeletonList({
    this.count = 3,
    this.semanticLabel = 'Loading',
    super.key,
  });

  /// Number of rows.
  final int count;

  /// Label read by screen readers.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: PaoSpace.md),
              child: Row(
                children: [
                  PaoSkeleton(height: 48, width: 48, radius: PaoRadius.md),
                  SizedBox(width: PaoSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaoSkeleton(),
                        SizedBox(height: PaoSpace.sm),
                        PaoSkeleton(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
