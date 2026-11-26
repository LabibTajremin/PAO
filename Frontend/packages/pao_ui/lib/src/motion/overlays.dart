import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// Shows a dialog that fades in and grows from 96% (`base`), and leaves
/// faster (`fast`). The light motion set fades only.
Future<T?> showPaoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  animationStyle: AnimationStyle(
    duration: context.motion(PaoMotion.base),
    reverseDuration: context.motion(PaoMotion.fast),
    curve: PaoMotion.enter,
    reverseCurve: PaoMotion.exit,
  ),
  builder: (context) => _Grow(child: builder(context)),
);

class _Grow extends StatelessWidget {
  const _Grow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || context.lightMotion) return child;
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.96,
        end: 1,
      ).animate(CurvedAnimation(parent: animation, curve: PaoMotion.enter)),
      child: child,
    );
  }
}

/// The sheet motion: slides up over `sheet`, leaves in `base`.
AnimationStyle paoSheetAnimation(BuildContext context) => AnimationStyle(
  duration: context.motion(PaoMotion.sheet),
  reverseDuration: context.motion(PaoMotion.base),
  curve: PaoMotion.enter,
  reverseCurve: PaoMotion.exit,
);
