import 'package:flutter/material.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Degrees moved per logical pixel dragged, about two metres in Dhaka: fine
/// enough to put the pin on the right building.
const _degreesPerPixel = 0.00002;

/// The pin on a map frame (C06). Dragging the frame moves the point under the
/// fixed centre pin, the way map apps do; [onMoved] fires when the drag ends.
class MapPicker extends StatefulWidget {
  /// Creates the picker at [point].
  const MapPicker({
    required this.point,
    required this.label,
    required this.onMoved,
    super.key,
  });

  /// Where the pin is.
  final GeoPoint point;

  /// Text under the pin, e.g. the area.
  final String label;

  /// Called with the new point after a drag.
  final ValueChanged<GeoPoint> onMoved;

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  Offset _drag = Offset.zero;

  GeoPoint get _moved => GeoPoint(
    widget.point.lat + _drag.dy * _degreesPerPixel,
    widget.point.lng - _drag.dx * _degreesPerPixel,
  );

  void _dragged(DragUpdateDetails d) => setState(() => _drag += d.delta);

  void _dropped(DragEndDetails _) {
    final moved = _moved;
    setState(() => _drag = Offset.zero);
    widget.onMoved(moved);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    final p = _moved;
    // Axis drags rather than a pan: they claim the gesture at the same slop
    // as the page's scroll view, so dragging the map never scrolls the page.
    return GestureDetector(
      onVerticalDragUpdate: _dragged,
      onVerticalDragEnd: _dropped,
      onHorizontalDragUpdate: _dragged,
      onHorizontalDragEnd: _dropped,
      child: PaoMapFrame(
        label: widget.label,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 40, color: accent.primary),
              Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
              Text(
                '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                context.t.locDragHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
