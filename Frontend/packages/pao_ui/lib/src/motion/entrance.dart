import 'package:flutter/widgets.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// Marks one list's first load: items mounted in its first frames rise in,
/// later ones (scrolled to, loaded on the next page, rebuilt) just appear.
class PaoEntranceGroup extends StatefulWidget {
  /// Groups the entrances below [child].
  const PaoEntranceGroup({required this.child, super.key});

  /// The list.
  final Widget child;

  @override
  State<PaoEntranceGroup> createState() => _PaoEntranceGroupState();
}

class _PaoEntranceGroupState extends State<PaoEntranceGroup> {
  bool _played = false;

  @override
  Widget build(BuildContext context) =>
      _Played(played: _played, child: widget.child);

  void _close() {
    if (mounted && !_played) setState(() => _played = true);
  }
}

class _Played extends InheritedWidget {
  const _Played({required this.played, required super.child});

  final bool played;

  @override
  bool updateShouldNotify(_Played old) => false;
}

/// Item [index] of a list fades in and rises 8 dp, 30 ms after the one before;
/// only the first six, only on the group's first load, never in the light
/// motion set.
class PaoEntrance extends StatefulWidget {
  /// Animates [child] in as item [index].
  const PaoEntrance({required this.index, required this.child, super.key});

  /// The item's position.
  final int index;

  /// The item.
  final Widget child;

  @override
  State<PaoEntrance> createState() => _PaoEntranceState();
}

class _PaoEntranceState extends State<PaoEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final group = context.findAncestorStateOfType<_PaoEntranceGroupState>();
    final played =
        context.getInheritedWidgetOfExactType<_Played>()?.played ?? true;
    if (played ||
        widget.index >= PaoMotion.staggeredItems ||
        context.lightMotion) {
      return;
    }
    final delay = PaoMotion.itemStagger * widget.index;
    final controller = _controller = AnimationController(
      vsync: this,
      duration: delay + PaoMotion.base,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => group?._close());
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    final start =
        widget.index *
        PaoMotion.itemStagger.inMicroseconds /
        controller.duration!.inMicroseconds;
    final shown = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: PaoMotion.enter),
    );
    return FadeTransition(
      opacity: shown,
      child: AnimatedBuilder(
        animation: shown,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, PaoMotion.itemRise * (1 - shown.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
