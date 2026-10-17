import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/shape.dart';
import 'package:pao_ui/src/tokens/typography.dart';
import 'package:pao_ui/src/widgets/button.dart';
import 'package:pao_ui/src/widgets/stitch.dart';

/// A centred icon, title, message and optional action; base of empty and error
/// screens. The icon sits in a stitched leaf frame, the brand's quiet motif.
class PaoMessageState extends StatelessWidget {
  /// Creates the state view.
  const PaoMessageState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  /// Illustration icon.
  final IconData icon;

  /// Heading.
  final String title;

  /// Explanation.
  final String? message;

  /// Button such as "Try again".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.pao;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: PaoSpace.xxl,
          vertical: PaoSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaoStitchFrame(
              frame: PaoShape.leaf,
              padding: PaoSpace.xs,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.tintFill,
                  borderRadius: PaoShape.leafSmall,
                ),
                child: Icon(icon, size: 26, color: c.action),
              ),
            ),
            const SizedBox(height: PaoSpace.lg),
            Text(
              title,
              style: paoDisplayStyle(18, c.ink),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: PaoSpace.sm),
              Text(
                message!,
                style: text.bodyMedium!.copyWith(color: c.inkMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: PaoSpace.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// "Nothing here yet" (e.g. C58 no bookings).
class PaoEmptyState extends PaoMessageState {
  /// Creates an empty state.
  const PaoEmptyState({
    required super.title,
    super.message,
    super.action,
    super.icon = Icons.inbox_outlined,
    super.key,
  });
}

/// A failure with a retry button.
class PaoErrorState extends StatelessWidget {
  /// Creates the error view; [onRetry] adds a [retryLabel] button.
  const PaoErrorState({
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    super.key,
  });

  /// Heading.
  final String title;

  /// Translated failure message.
  final String message;

  /// Retries the failed load.
  final VoidCallback? onRetry;

  /// Retry button text.
  final String retryLabel;

  @override
  Widget build(BuildContext context) => PaoMessageState(
    icon: Icons.cloud_off_outlined,
    title: title,
    message: message,
    action: onRetry == null
        ? null
        : PaoButton(label: retryLabel, onPressed: onRetry, expand: false),
  );
}
