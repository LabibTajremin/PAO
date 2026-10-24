import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';

/// Paints the kantha stitch, PAO's motif: short evenly spaced dashes like a
/// running stitch in nakshi kantha embroidery. With [frame] it outlines the
/// canvas with those corners; without it, it runs along the longer side.
class PaoStitchPainter extends CustomPainter {
  /// Creates the painter.
  const PaoStitchPainter({required this.color, this.frame});

  /// Thread colour.
  final Color color;

  /// Corners of the outline; null draws a straight line.
  final BorderRadius? frame;

  /// Stitch length.
  static const double dash = 5;

  /// Gap between stitches.
  static const double gap = 4;

  /// Thread width.
  static const double thread = 1.5;

  Path _path(Size size) {
    if (frame != null) {
      const inset = thread / 2;
      final rect = (Offset.zero & size).deflate(inset);
      return Path()..addRRect(frame!.toRRect(rect));
    }
    final y = size.height / 2;
    final x = size.width / 2;
    return size.width >= size.height
        ? (Path()
            ..moveTo(0, y)
            ..lineTo(size.width, y))
        : (Path()
            ..moveTo(x, 0)
            ..lineTo(x, size.height));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thread
      ..strokeCap = StrokeCap.round;
    for (final metric in _path(size).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        final end = (d + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(PaoStitchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.frame != frame;
}

/// A straight kantha stitch, horizontal by default.
class PaoStitch extends StatelessWidget {
  /// Creates a stitch of [length]; null fills the available space.
  const PaoStitch({
    this.axis = Axis.horizontal,
    this.length,
    this.color,
    super.key,
  });

  /// Direction of the line.
  final Axis axis;

  /// Length of the line.
  final double? length;

  /// Thread colour; defaults to the accent stitch colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final across = axis == Axis.horizontal;
    return ExcludeSemantics(
      child: SizedBox(
        width: across ? length ?? double.infinity : 2,
        height: across ? 2 : length ?? double.infinity,
        child: CustomPaint(
          painter: PaoStitchPainter(color: color ?? context.pao.stitch),
        ),
      ),
    );
  }
}

/// A section divider drawn as a kantha stitch.
class PaoStitchDivider extends StatelessWidget {
  /// Creates the divider.
  const PaoStitchDivider({this.spacing = PaoSpace.lg, super.key});

  /// Space above and below the stitch.
  final double spacing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: spacing),
    child: const PaoStitch(),
  );
}

/// Outlines [child] with a kantha stitch following [frame].
class PaoStitchFrame extends StatelessWidget {
  /// Creates the frame.
  const PaoStitchFrame({
    required this.child,
    required this.frame,
    this.padding = PaoSpace.sm,
    super.key,
  });

  /// Framed content.
  final Widget child;

  /// Corners of the stitched outline.
  final BorderRadius frame;

  /// Space between the stitch and [child].
  final double padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: PaoStitchPainter(color: context.pao.stitch, frame: frame),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}
