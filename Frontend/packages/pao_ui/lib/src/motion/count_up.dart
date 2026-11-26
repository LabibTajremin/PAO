import 'package:flutter/widgets.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// Counts from zero up to [value] over `emphasis` on a dashboard, then
/// follows later changes from where it stands. Only the text rebuilds per
/// frame. The light motion set shows [value] at once.
class PaoCountUp extends StatelessWidget {
  /// Shows [value] through [builder].
  const PaoCountUp({required this.value, required this.builder, super.key});

  /// Where the count ends.
  final int value;

  /// Shows the count so far.
  final Widget Function(BuildContext context, int shown) builder;

  @override
  Widget build(BuildContext context) {
    if (context.lightMotion) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: PaoMotion.emphasis,
      curve: PaoMotion.emphasized,
      builder: (context, shown, _) => builder(context, shown.round()),
    );
  }
}
