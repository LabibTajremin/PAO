import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// The success moment: an accent disc whose check mark draws itself
/// (`emphasis`) while one small ring of palette dots bursts out and fades.
/// It paints from one controller, with no rebuilds. The light motion set shows
/// the finished mark with no burst.
class PaoSuccessMark extends StatefulWidget {
  /// Creates the mark [size] logical pixels wide.
  const PaoSuccessMark({this.size = 72, super.key});

  /// Diameter of the disc.
  final double size;

  @override
  State<PaoSuccessMark> createState() => _PaoSuccessMarkState();
}

class _PaoSuccessMarkState extends State<PaoSuccessMark>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: PaoMotion.emphasis,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (context.lightMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pao;
    return Semantics(
      image: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size * 1.6),
          painter: _MarkPainter(
            progress: CurvedAnimation(
              parent: _controller,
              curve: PaoMotion.emphasized,
            ),
            disc: c.action,
            tick: PaoColors.onPrimary,
            dots: [c.stitch, c.action, c.selectedFill],
            burst: !context.lightMotion,
            radius: widget.size / 2,
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.progress,
    required this.disc,
    required this.tick,
    required this.dots,
    required this.burst,
    required this.radius,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color disc;
  final Color tick;
  final List<Color> dots;
  final bool burst;
  final double radius;

  static const _count = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final centre = size.center(Offset.zero);
    canvas.drawCircle(centre, radius, Paint()..color = disc);
    final path = Path()
      ..moveTo(centre.dx - radius * 0.4, centre.dy)
      ..lineTo(centre.dx - radius * 0.1, centre.dy + radius * 0.3)
      ..lineTo(centre.dx + radius * 0.45, centre.dy - radius * 0.3);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = tick
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (!burst || t >= 1) return;
    final reach = radius * (1.05 + 0.45 * t);
    for (var i = 0; i < _count; i++) {
      final angle = i * 2 * math.pi / _count;
      canvas.drawCircle(
        centre + Offset(math.cos(angle), math.sin(angle)) * reach,
        radius * 0.07,
        Paint()..color = dots[i % dots.length].withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.disc != disc || old.burst != burst || old.radius != radius;
}
