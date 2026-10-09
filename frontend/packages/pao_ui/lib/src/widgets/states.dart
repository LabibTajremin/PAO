import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/widgets/button.dart';

/// A centred icon, title, message and optional action; base of empty and error
/// screens.
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
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PaoSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: context.pao.accent.primary),
            const SizedBox(height: PaoSpace.lg),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: PaoSpace.sm),
              Text(
                message!,
                style: text.bodyMedium!.copyWith(
                  color: PaoColors.textSecondary,
                ),
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
