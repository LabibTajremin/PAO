import 'package:flutter/material.dart';
import 'package:pao_ui/src/motion/opening_logo.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// The cold-start opening (P27): the splash tile, then the letters settle
/// while [ready] loads, then the logo rises and fades as [child] fades in and
/// rises 12 dp — about 560 ms when loading is quick. A slow load keeps the
/// settled logo with a slim progress line, never a spinner. [child] is built
/// only once [ready] is done, so routing starts with the session loaded.
/// Without [ready] (warm starts, tests) [child] shows at once.
class PaoOpening extends StatefulWidget {
  /// Opens on [child] once [ready] completes.
  const PaoOpening({required this.child, this.ready, super.key});

  /// What has to load before the first screen; errors count as done.
  final Future<void>? ready;

  /// The app.
  final Widget child;

  @override
  State<PaoOpening> createState() => _PaoOpeningState();
}

class _PaoOpeningState extends State<PaoOpening> with TickerProviderStateMixin {
  late final _settle = AnimationController(
    vsync: this,
    duration: openingSettle,
  );
  late final _leave = AnimationController(
    vsync: this,
    duration: PaoMotion.base,
  );
  late bool _loaded = widget.ready == null;
  late bool _gone = widget.ready == null;

  @override
  void initState() {
    super.initState();
    if (_gone) return;
    _settle.addStatusListener((_) => _maybeLeave());
    _leave.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _gone = true);
      }
    });
    widget.ready!.whenComplete(() {
      if (!mounted) return;
      setState(() => _loaded = true);
      _maybeLeave();
    }).ignore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gone || _settle.isAnimating || _settle.isCompleted) return;
    // The light set skips the settle and only cross-fades.
    if (context.lightMotion) {
      _settle.value = 1;
      _leave.duration = context.motion(PaoMotion.base);
    } else {
      _settle.forward();
    }
  }

  void _maybeLeave() {
    if (_loaded && _settle.isCompleted && !_leave.isAnimating) _leave.forward();
  }

  @override
  void dispose() {
    _settle.dispose();
    _leave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final leave = CurvedAnimation(parent: _leave, curve: PaoMotion.enter);
    final fade = ReverseAnimation(leave);
    final still = context.lightMotion;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_loaded)
          FadeTransition(
            opacity: leave,
            child: SlideTransition(
              position: Tween(
                begin: Offset(0, still ? 0 : PaoMotion.rise / 800),
                end: Offset.zero,
              ).animate(leave),
              child: widget.child,
            ),
          ),
        IgnorePointer(
          ignoring: _loaded,
          child: FadeTransition(
            opacity: fade,
            child: ColoredBox(
              color: dark ? PaoSplash.dark : PaoSplash.light,
              child: _Logo(
                settle: _settle,
                leave: leave,
                dark: dark,
                waiting: !_loaded,
                still: still,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({
    required this.settle,
    required this.leave,
    required this.dark,
    required this.waiting,
    required this.still,
  });

  final AnimationController settle;
  final Animation<double> leave;
  final bool dark;
  final bool waiting;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final up = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, still ? 0 : -PaoMotion.slide / PaoSplash.tile),
    ).animate(leave);
    return Center(
      child: RepaintBoundary(
        child: SlideTransition(
          position: up,
          child: OverflowBox(
            maxHeight: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Keeps the tile on the screen's centre line, as on the splash.
                const SizedBox(height: _line + _gap),
                OpeningLogo(progress: settle, dark: dark),
                const SizedBox(height: _gap),
                SizedBox(
                  width: PaoSplash.tile * 0.6,
                  height: _line,
                  child: AnimatedBuilder(
                    animation: settle,
                    builder: (_, line) => waiting && settle.isCompleted
                        ? line!
                        : const SizedBox(),
                    child: const LinearProgressIndicator(minHeight: _line),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _line = 2.0;
  static const _gap = 24.0;
}
