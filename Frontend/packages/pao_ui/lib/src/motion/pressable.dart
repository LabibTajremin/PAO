import 'package:flutter/widgets.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// Shrinks [child] to 97% while a finger is on it (`press`), and back on
/// release. It only listens to pointers, so taps, scrolls and semantics pass
/// straight through. Off when [enabled] is false or in the light motion set.
class PaoPressable extends StatefulWidget {
  /// Wraps [child].
  const PaoPressable({required this.child, this.enabled = true, super.key});

  /// What is pressed.
  final Widget child;

  /// Whether it reacts.
  final bool enabled;

  @override
  State<PaoPressable> createState() => _PaoPressableState();
}

class _PaoPressableState extends State<PaoPressable>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: PaoMotion.press,
  );
  late final Animation<double> _scale = Tween<double>(begin: 1, end: 0.97)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: PaoMotion.enter,
          reverseCurve: PaoMotion.exit,
        ),
      );

  void _down(PointerDownEvent _) {
    if (widget.enabled && !context.lightMotion) _controller.forward();
  }

  void _up(PointerEvent _) => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _up,
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
