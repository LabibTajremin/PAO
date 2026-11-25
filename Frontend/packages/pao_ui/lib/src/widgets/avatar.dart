import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/colors.dart';

/// A round photo, or initials when there is none.
class PaoAvatar extends StatelessWidget {
  /// Creates an avatar for [name].
  const PaoAvatar({required this.name, this.image, this.size = 48, super.key});

  /// Person's name; used for initials and the semantic label.
  final String name;

  /// Photo, if any.
  final ImageProvider? image;

  /// Diameter in logical pixels.
  final double size;

  /// Up to two initials, e.g. "RU" for "Rahim Uddin".
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    return parts.take(2).map((p) => p.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    final photo = image;
    // Decoded at the size drawn, so a large upload never fills memory.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Semantics(
      label: name,
      image: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: accent.soft,
        foregroundImage: photo == null
            ? null
            : ResizeImage.resizeIfNeeded(pixels, pixels, photo),
        child: ExcludeSemantics(
          child: Text(
            initials(name),
            style: TextStyle(
              color: accent.strong,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.36,
            ),
          ),
        ),
      ),
    );
  }
}
