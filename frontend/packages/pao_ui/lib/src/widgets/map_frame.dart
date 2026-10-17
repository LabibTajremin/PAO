import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/shape.dart';

/// A framed area for a map, with a centred pin and [label] until the real map
/// loads (or when maps are unavailable).
class PaoMapFrame extends StatelessWidget {
  /// Creates the frame; [child] is the map when there is one.
  const PaoMapFrame({
    required this.label,
    this.child,
    this.height = 200,
    super.key,
  });

  /// Text under the pin, e.g. the area name.
  final String label;

  /// The map widget.
  final Widget? child;

  /// Frame height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.pao;
    return ClipRRect(
      borderRadius: PaoShape.leaf,
      child: Container(
        height: height,
        color: c.tintFill,
        child:
            child ??
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 40, color: c.action),
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
      ),
    );
  }
}
