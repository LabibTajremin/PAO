import 'package:flutter/material.dart';
import 'package:pao_admin/shared/l10n.dart';

/// Largest zoom the buttons and pinch allow.
const maxZoom = 6.0;

/// A picture that can be panned, zoomed (pinch, wheel or buttons) and turned
/// in 90° steps.
class ZoomableImage extends StatefulWidget {
  /// Creates the view around [child].
  const ZoomableImage({required this.child, super.key});

  /// The picture.
  final Widget child;

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  final _zoom = TransformationController();
  var _turns = 0;
  Size _size = Size.zero;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  // Scales about the middle of the view so the part being looked at stays
  // in sight.
  void _scaleBy(double factor) {
    final scale = (_zoom.value.getMaxScaleOnAxis() * factor).clamp(
      1.0,
      maxZoom,
    );
    final c = _size.center(Offset.zero);
    _zoom.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw((1 - scale) * c.dx, (1 - scale) * c.dy, 0);
  }

  void _turn(int by) => setState(() => _turns = (_turns + by) % 4);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (_, box) {
              _size = box.biggest;
              return ClipRect(
                child: InteractiveViewer(
                  transformationController: _zoom,
                  maxScale: maxZoom,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: _turns,
                      child: widget.child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _toolbar(context),
      ],
    );
  }

  Widget _toolbar(BuildContext context) {
    final t = context.t;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tool(Icons.zoom_in, t.verifyViewerZoomIn, () => _scaleBy(1.5)),
        _tool(Icons.zoom_out, t.verifyViewerZoomOut, () => _scaleBy(1 / 1.5)),
        _tool(Icons.rotate_left, t.verifyViewerRotateLeft, () => _turn(3)),
        _tool(Icons.rotate_right, t.verifyViewerRotateRight, () => _turn(1)),
        ValueListenableBuilder(
          valueListenable: _zoom,
          builder: (_, m, _) => Text(
            '${(m.getMaxScaleOnAxis() * 100).round()}% · ${_turns * 90}°',
          ),
        ),
      ],
    );
  }

  Widget _tool(IconData icon, String tip, VoidCallback onPressed) =>
      IconButton(icon: Icon(icon), tooltip: tip, onPressed: onPressed);
}
