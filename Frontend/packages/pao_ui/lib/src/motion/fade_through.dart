import 'package:flutter/widgets.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// Fades [child] in again whenever [index] changes: the bottom-tab switch.
/// The tabs keep their state in the shell's own stack; only the opacity of
/// the visible one animates, so nothing is rebuilt per frame.
class PaoFadeThrough extends StatefulWidget {
  /// Fades [child] in on every change of [index].
  const PaoFadeThrough({required this.index, required this.child, super.key});

  /// The selected tab.
  final int index;

  /// The tab stack.
  final Widget child;

  @override
  State<PaoFadeThrough> createState() => _PaoFadeThroughState();
}

class _PaoFadeThroughState extends State<PaoFadeThrough>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PaoMotion.base,
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: PaoMotion.enter,
  );

  @override
  void didUpdateWidget(PaoFadeThrough old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _controller
      ..duration = context.motion(PaoMotion.base)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(opacity: _opacity, child: widget.child),
  );
}
